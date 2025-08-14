# Future Authentication System Roadmap

## Current System (Phase 1 - IMPLEMENTED)
- **Anonymous UUID Players**: Instant play with collision-free identities
- **Device Binding**: Usernames bound to device fingerprint for security
- **Multiple Players Per Device**: Unlimited UUID players per machine
- **Desktop Shortcuts**: Easy return access via UUID shortcuts

## Phase 2 - Simple Registration System (NEXT)

### Username + Password (No Email Required)
```gdscript
# Simple registration - just username/password
func register_simple_account(username: String, password: String) -> bool:
    if username in accounts:
        return false  # Username taken
    
    accounts[username] = {
        "password_hash": password.sha256_text(),
        "uuid_player": current_player_uuid,
        "device_fingerprint": get_device_fingerprint(),  # For extra security
        "created_at": Time.get_datetime_string_from_system()
    }
    save_accounts()
    return true

func login_simple_account(username: String, password: String) -> String:
    if username in accounts:
        var stored_hash = accounts[username]["password_hash"]
        if stored_hash == password.sha256_text():
            return accounts[username]["uuid_player"]  # Success
    return ""  # Failed login
```

### Benefits
- ✅ **No Email Required**: Just username + password
- ✅ **Instant Registration**: Link current UUID player to account
- ✅ **Remember Login**: Optional "stay logged in" checkbox
- ✅ **Cross-Device**: Login from any computer with credentials
- ✅ **Fallback Security**: Still uses device binding as backup

### User Flow
1. **Anonymous Player**: Start playing immediately with UUID
2. **Optional Registration**: "Claim this character" with username/password  
3. **Future Logins**: Enter credentials to resume character
4. **Device Memory**: Optionally remember login on trusted devices

## Phase 3 - Device Binding Enhancement

### Device Fingerprinting Strategy
```gdscript
func get_device_fingerprint() -> String:
    var factors = [
        OS.get_unique_id(),           # Hardware ID
        OS.get_processor_name(),      # CPU info
        str(OS.get_processor_count()),# CPU cores
        OS.get_model_name(),          # Device model
        str(DisplayServer.screen_get_size()), # Screen resolution
    ]
    return factors.join("|").sha256_text()
```

### Security Features
- **Username Claims**: `register_username("john_doe")` binds to current device
- **Login Verification**: Username only works on original device
- **Multi-Player Support**: Same device can have unlimited UUID players
- **Anti-Hijacking**: Prevents casual account stealing

### Attack Resistance
- ✅ **UUID Space**: 2^122 combinations = impossible to exhaust
- ✅ **Device Isolation**: Account hijacking requires physical access
- ✅ **Brute Force Immunity**: Can't guess valid UUIDs or device fingerprints

## Phase 4 - Steam Integration (FUTURE)

### Steam Authority System
```gdscript
# Steam integration for verified accounts
func verify_steam_account() -> SteamVerification:
    var steam_id = Steam.get_steam_id()
    var steam_name = Steam.get_persona_name() 
    var steam_level = Steam.get_steam_level()
    
    return {
        "steam_id": steam_id,
        "display_name": steam_name,
        "level": steam_level,
        "verified": true,
        "linked_uuid": current_player_uuid
    }
```

### Visual Verification Indicators
- **🟢 Steam Verified**: Green username with Steam icon
- **🔵 Device Bound**: Blue username (local account)  
- **⚪ Anonymous**: White username (UUID only)
- **👑 High Level**: Special crowns for Steam level 50+
- **🌟 Achievement Badges**: Steam achievement integration

### Cross-Platform Authority
- **Steam Workshop**: Share world saves via Steam Workshop
- **Steam Friends**: Invite Steam friends to your world
- **Steam Achievements**: Game progress tied to Steam account
- **Steam Cloud**: Save player data to Steam cloud
- **Anti-Cheat**: Steam VAC integration for competitive play

## Phase 5 - Advanced Features (FUTURE)

### Multi-Platform Verification
- **Discord Integration**: Link Discord accounts for voice chat
- **Google/Apple OAuth**: Mobile platform verification
- **Twitch Integration**: Streamer verification and viewer interaction
- **Epic Games**: Cross-platform with Epic accounts

### Account Recovery System
```gdscript
# Multi-factor account recovery
func recover_account(username: String) -> RecoveryOptions:
    return {
        "steam_recovery": verify_steam_ownership(),
        "email_recovery": send_recovery_email(),
        "backup_codes": verify_recovery_codes(),
        "trusted_device": verify_device_history()
    }
```

### Enhanced Security
- **Two-Factor Authentication**: SMS/Authenticator app support
- **Session Management**: Active session monitoring and control
- **Trusted Devices**: Add/remove authorized devices
- **Login Notifications**: Alert when account accessed from new device

## Implementation Priority

### Phase 2 (Next Sprint)
1. ✅ Simple username + password registration
2. ✅ Login system with password hashing
3. ✅ "Remember me" functionality
4. ✅ Account linking to existing UUID players

### Phase 3 (Device Binding)
1. ✅ Device fingerprinting system
2. ✅ Additional security layer
3. ✅ Anti-hijacking protection
4. ✅ Cross-device verification

### Phase 4 (Steam Integration)
1. Steam SDK integration
2. Steam ID verification
3. Visual verification system
4. Steam friend invitations
5. Achievement system

### Phase 5 (Advanced Features)
1. Multi-platform OAuth
2. Account recovery system
3. Two-factor authentication
4. Session management
5. Cross-platform sync

## Security Philosophy

### "Progressive Trust" Model
1. **Anonymous** → Instant play, no barriers (UUID only)
2. **Simple Account** → Username + password, cross-device access
3. **Device Bound** → Additional security layer, trusted devices
4. **Steam Verified** → High trust, cross-platform features
5. **Multi-Factor** → Maximum security, valuable accounts

### No Forced Registration
- Players can remain anonymous forever
- Each verification level adds benefits, not restrictions
- Backward compatibility with all authentication levels
- Optional upgrades preserve existing progress

## Technical Architecture

### Database Schema
```sql
-- Player progression
players (uuid_id, progress_data, inventory, position)

-- Authentication layers  
device_accounts (username, device_fingerprint, uuid_player)
steam_accounts (steam_id, username, uuid_player, verified_at)
oauth_accounts (provider, external_id, uuid_player)

-- Security audit
login_history (uuid_player, device_fingerprint, timestamp, success)
```

### API Design
```gdscript
# Unified authentication interface
var auth = AuthenticationManager.new()

# Layer 1: Anonymous
var player = auth.create_anonymous_player()

# Layer 2: Device binding  
auth.bind_username_to_device("john_doe", player.uuid)

# Layer 3: Steam verification
auth.verify_steam_account(steam_id, player.uuid)

# Layer 4: Multi-factor
auth.enable_two_factor(player.uuid, phone_number)
```

This system scales from "just play" simplicity to enterprise-grade security while preserving player choice and progress at every level.