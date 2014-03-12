/*
 * Copyright (C) 2001-2014 Jacek Sieka, arnetheduck on gmail point com
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#include "stdinc.h"
#include "Client.h"
#include "BufferedSocket.h"
#include "FavoriteManager.h"
#include "TimerManager.h"
#include "ClientManager.h"
#include "LogManager.h"
#include "DebugManager.h"
#include "PluginManager.h"
#include "ConnectivityManager.h"
#include "AdcHub.h" // for dynamic_cast

namespace dcpp {

atomic<long> Client::counts[COUNT_UNCOUNTED];

Client::Client(const string& hubURL, char separator_, bool secure_) :
	myIdentity(ClientManager::getInstance()->getMe(), 0),
	reconnDelay(120), lastActivity(GET_TICK()), registered(false), autoReconnect(false),
	encoding(Text::systemCharset), state(STATE_DISCONNECTED), sock(0),
	hubUrl(hubURL),separator(separator_),
	secure(secure_), countType(COUNT_UNCOUNTED)
{
	string file, proto, query, fragment;
	Util::decodeUrl(hubURL, proto, address, port, file, query, fragment);
	keyprint = Util::decodeQuery(query)["kp"];
	TimerManager::getInstance()->addListener(this);

	//RSX++
	setCheckAtConnect(false);
	cmdQueue.setClientPtr(this);
}

Client::~Client() {
	dcassert(!sock);

	// In case we were deleted before we Failed
	FavoriteManager::getInstance()->removeUserCommand(getHubUrl());
	TimerManager::getInstance()->removeListener(this);
	updateCounts(true);
}

void Client::reconnect() {
	disconnect(true);
	setAutoReconnect(true);
	setReconnDelay(0);
}

void Client::shutdown() {
	state = STATE_DISCONNECTED;
	//RSX++
	cmdQueue.clear();
	putDetectors();
	//END
	if(sock) {
		BufferedSocket::putSocket(sock);
		sock = nullptr;
	}
}

void Client::reloadSettings(bool updateNick) {
	/// @todo update the nick in ADC hubs?
	string prevNick = Util::emptyString;
	if(!updateNick)
		prevNick = get(Nick);

	*static_cast<HubSettings*>(this) = SettingsManager::getInstance()->getHubSettings();

	FavoriteHubEntry* fav = FavoriteManager::getInstance()->getFavoriteHubEntry(getHubUrl());
	if(fav)
	{
		FavoriteManager::getInstance()->mergeHubSettings(*fav, *this);
		if(!fav->getPassword().empty())
			setPassword(fav->getPassword());
		//[BMDC
		setHideShare(fav->getHideShare());
		setChatExtraInfo(fav->getChatExtraInfo());
		setProtectUser(fav->getProtectUsers());
		setCheckAtConnect(fav->getCheckAtConn());
		setCheckClients(fav->getCheckClients());
		setCheckFilelists(fav->getCheckFilelists());
		setTabText(fav->getTabText());
		setTabIconStr(fav->getTabIconStr());
		//]
	}else{
		//[BMDC++
		setHideShare(false);
		setChatExtraInfo(Util::emptyString);
		setProtectUser(Util::emptyString);
		setCheckAtConnect(false);
		setCheckClients(false);
		setCheckFilelists(false);
		setTabText(Util::emptyString);
		setTabIconStr(Util::emptyString);
        //]
	}
	if(updateNick)
        checkNick(get(Nick));
	else
		get(Nick) = prevNick;
}

const string& Client::getUserIp() const {
	if(!get(UserIp).empty()) {
		return get(UserIp);
	}
	return CONNSETTING(EXTERNAL_IP);
}

void Client::connect() {
	if(sock) {
		BufferedSocket::putSocket(sock);
		sock = nullptr;
	}

	setAutoReconnect(true);
	
	if((uint32_t)SETTING(TIME_RECCON) > 10)
        setReconnDelay((uint32_t)(SETTING(TIME_RECCON)));
	else
       	setReconnDelay(120 + Util::rand(0, 60));
	
	reloadSettings(true);
	setRegistered(false);
	setMyIdentity(Identity(ClientManager::getInstance()->getMe(), 0));
	setHubIdentity(Identity());

	state = STATE_CONNECTING;

	try {
		sock = BufferedSocket::getSocket(separator, v4only());
		sock->addListener(this);
		sock->connect(address, port, secure, SETTING(ALLOW_UNTRUSTED_HUBS), true);
	} catch(const Exception& e) {
		state = STATE_DISCONNECTED;
		fire(ClientListener::Failed(), this, e.getError());
	}
	updateActivity();
}

void Client::send(const char* aMessage, size_t aLen) {
	if(!isConnected()) {
		dcassert(0);
		LogManager::getInstance()->message("Not Connected returning");
		return;
	}
	COMMAND_DEBUG(aMessage,TYPE_HUB,OUTGOING, getHubUrl());

	if(PluginManager::getInstance()->runHook(HOOK_NETWORK_HUB_OUT, this, aMessage))
		return;

	updateActivity();
	sock->write(aMessage, aLen);
}

HubData* Client::getPluginObject() noexcept {
	resetEntity();

	pod.url = pluginString(hubUrl);
	pod.ip = pluginString(ip);
	pod.object = this;
	pod.port = Util::toInt(port);
	pod.protocol = dynamic_cast<AdcHub*>(this) ? PROTOCOL_ADC : PROTOCOL_NMDC; // TODO: dynamic_cast not practical if more than two protocols
	pod.isOp = isOp() ? True : False;
	pod.isSecure = isSecure() ? True : False;

	return &pod;
}

void Client::on(Connected) noexcept {
	updateActivity();
	ip = sock->getIp();
/*
	if(sock->isSecure() && keyprint.compare(0, 7, "SHA256/") == 0) {
		vector<uint8_t> kp = sock->getKeyprint();
		if(!kp.empty()) {
			vector<uint8_t> kp2v(kp.size());
			Encoder::fromBase32(keyprint.c_str() + 7, &kp2v[0], kp2v.size());
			if(!std::equal(kp.begin(), kp.end(), kp2v.begin())) {
				state = STATE_DISCONNECTED;
				sock->removeListener(this);
				fire(ClientListener::Failed(), this, "Keyprint mismatch");
				return;
			}
		}
	}*/

	fire(ClientListener::Connected(), this);
	state = STATE_PROTOCOL;
}

void Client::on(Failed, const string& aLine) noexcept {
	state = STATE_DISCONNECTED;
	FavoriteManager::getInstance()->removeUserCommand(getHubUrl());
	fire(ClientListener::Failed(), this, aLine);
}

void Client::disconnect(bool graceLess) {
	state = STATE_DISCONNECTED;
	if(sock)
		sock->disconnect(graceLess);
}

bool Client::isSecure() const {
	return isConnected() && sock->isSecure();
}

bool Client::isTrusted() const {
	return isConnected() && sock->isTrusted();
}

std::string Client::getCipherName() const {
	return isConnected() ? sock->getCipherName() : Util::emptyString;
}

vector<uint8_t> Client::getKeyprint() const {
	return isConnected() ? sock->getKeyprint() : vector<uint8_t>();
}

bool Client::isActive() const {
	return ClientManager::getInstance()->isActive(hubUrl);
}

void Client::updateCounts(bool aRemove) {
	// We always remove the count and then add the correct one if requested...
	if(countType != COUNT_UNCOUNTED) {
		--counts[countType];
		countType = COUNT_UNCOUNTED;
	}

	if(!aRemove) {
		if(getMyIdentity().isOp()) {
			countType = COUNT_OP;
		} else if(getMyIdentity().isRegistered()) {
			countType = COUNT_REGISTERED;
		} else {
			countType = COUNT_NORMAL;
		}
		++counts[countType];
	}
}

string Client::getCounts() {
	char buf[128];
	return string(buf, snprintf(buf, sizeof(buf), "%ld/%ld/%ld",
		counts[COUNT_NORMAL].load(), counts[COUNT_REGISTERED].load(), counts[COUNT_OP].load()));
}

void Client::on(Line, const string& aLine) noexcept {
	updateActivity();
	COMMAND_DEBUG(aLine, TYPE_HUB, INCOMING, getIpPort());
}

void Client::on(Second, uint64_t aTick) noexcept {
	if(state == STATE_DISCONNECTED && getAutoReconnect() && (aTick > (getLastActivity() + getReconnDelay() * 1000)) ) {
		// Try to reconnect...
		connect();
	}

	if(isConnected()){
		cmdQueue.onSecond(aTick); //RSX++/BMDC++
	}
}

void Client::sendActionCommand(const OnlineUser& ou, int actionId) {
	if(!isConnected() /*|| (userCount < getUsersLimit())*/)
		return;
	cmdQueue.addCommand(ou, actionId);
}

bool Client::isActionActive(const int aAction) const {
	FavoriteHubEntry* hub = FavoriteManager::getInstance()->getFavoriteHubEntry(getHubUrl());
	return hub ? FavoriteManager::getInstance()->getEnabledAction(hub, aAction) : true;
}

} // namespace dcpp
