// copy from https://github.com/DosMike/SM-MiscPlugins
/**
 * Since MAXPLAYERS is 101 now, managing flag bits for players is a bit tedious
 * This include should help with that.
 * Cheat sheet:
 *  - clear bits: bits.Xor(bits);
 *  - copy bits: to.Xor(to); to.Or(from);
 */

#pragma newdecls required
#pragma semicolon 1

enum struct PlayerBits {
	int partition[4]; // up to 128 players
	
	PlayerBits Or(int index) {
		this.partition[index/32] |= (1<<(index%32));
		return this;
	}
	PlayerBits OrBits(PlayerBits other) {
		this.partition[0] |= other.partition[0];
		this.partition[1] |= other.partition[1];
		this.partition[2] |= other.partition[2];
		this.partition[3] |= other.partition[3];
		return this;
	}
	PlayerBits OrNot(int index) {
		this.partition[index/32] |=~ (1<<(index%32));
		return this;
	}
	PlayerBits OrNotBits(PlayerBits other) {
		this.partition[0] |=~ other.partition[0];
		this.partition[1] |=~ other.partition[1];
		this.partition[2] |=~ other.partition[2];
		this.partition[3] |=~ other.partition[3];
		return this;
	}
	PlayerBits And(int index) {
		this.partition[index/32] &= (1<<(index%32));
		return this;
	}
	PlayerBits AndBits(PlayerBits other) {
		this.partition[0] &= other.partition[0];
		this.partition[1] &= other.partition[1];
		this.partition[2] &= other.partition[2];
		this.partition[3] &= other.partition[3];
		return this;
	}
	PlayerBits AndNot(int index) {
		this.partition[index/32] &=~ (1<<(index%32));
		return this;
	}
	PlayerBits AndNotBits(PlayerBits other) {
		this.partition[0] &=~ other.partition[0];
		this.partition[1] &=~ other.partition[1];
		this.partition[2] &=~ other.partition[2];
		this.partition[3] &=~ other.partition[3];
		return this;
	}
	PlayerBits Xor(int index) {
		int part = index/32;
		int mask = (1<<(index%32));
		this.partition[part] ^= mask;
		return this;
	}
	PlayerBits XorBits(PlayerBits other) {
		this.partition[0] ^= other.partition[0];
		this.partition[1] ^= other.partition[1];
		this.partition[2] ^= other.partition[2];
		this.partition[3] ^= other.partition[3];
		return this;
	}
	PlayerBits Not() {
		this.partition[0] =~ this.partition[0];
		this.partition[1] =~ this.partition[1];
		this.partition[2] =~ this.partition[2];
		this.partition[3] =~ this.partition[3];
		return this;
	}
	void Set(int index, bool active) {
		if (active) this.Or(index);
		else this.AndNot(index);
	}
	bool Get(int index) {
		return (this.partition[index/32] & (1<<(index%32))) != 0;
	}
	
	PlayerBits SetTeam(int team) {
		for (int client=1; client <= MaxClients; client++)
			if (IsClientInGame(client) && GetClientTeam(client) == team)
				this.Or(client);
		return this;
	}
	PlayerBits SetAlive() {
		for (int client=1; client <= MaxClients; client++)
			if (IsClientInGame(client) && IsPlayerAlive(client))
				this.Or(client);
		return this;
	}
	
	int ToArray(int[] player, int maxplayers) {
		int i;
		for (int client=1; client <= MaxClients && i < maxplayers; client++) {
			if (this.Get(client)) { 
				player[i] = client;
				i++;
			}
		}
		return i;
	}
	int ToArrayList(ArrayList list) {
		for (int client=1; client <= MaxClients; client++) {
			if (this.Get(client)) { 
				list.Push(client);
			}
		}
		return list.Length;
	}
	
	bool Any() {
		return this.partition[0] || this.partition[1] || this.partition[2] || this.partition[3];
	}
	int Count() {
		int count;
		for (int i=0; i<32; i++) {
			count += ((this.partition[0] & (1<<i)) ? 1 : 0) +
					((this.partition[1] & (1<<i)) ? 1 : 0) +
					((this.partition[2] & (1<<i)) ? 1 : 0) +
					((this.partition[3] & (1<<i)) ? 1 : 0);
		}
		return count;
	}
}
