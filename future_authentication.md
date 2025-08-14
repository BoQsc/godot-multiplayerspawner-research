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
func register_simple_account(username: String, password: String, enable_device_binding: bool = true) -> bool:
    if username in accounts:
        return false  # Username taken
    
    accounts[username] = {
        "password_hash": password.sha256_text(),
        "uuid_player": current_player_uuid,
        "device_binding_enabled": enable_device_binding,
        "trusted_devices": [get_device_fingerprint()] if enable_device_binding else [],
        "created_at": Time.get_datetime_string_from_system()
    }
    save_accounts()
    return true

func login_simple_account(username: String, password: String) -> String:
    if username in accounts:
        var account = accounts[username]
        var stored_hash = account["password_hash"]
        
        if stored_hash == password.sha256_text():
            # Check device binding if enabled
            if account["device_binding_enabled"]:
                var current_device = get_device_fingerprint()
                if not current_device in account["trusted_devices"]:
                    return "DEVICE_NOT_TRUSTED"  # Requires device authorization
            
            return account["uuid_player"]  # Success
    return ""  # Failed login
```

### Security Options (User Choice)
```gdscript
# In-game settings panel
[✓] Enable device binding (recommended)
    └─ Only allow login from trusted devices
[ ] Require new device confirmation  
[ ] Remember login on this device
[⚙️] Manage trusted devices (3 devices)
```

### Benefits
- ✅ **No Email Required**: Just username + password
- ✅ **Instant Registration**: Link current UUID player to account
- ✅ **Cross-Device**: Login from any computer with credentials
- ✅ **Optional Device Binding**: Toggle on/off anytime
- ✅ **Anonymous Flexibility**: Untick device binding for device freedom

### User Flow
1. **Anonymous Player**: Start playing immediately with UUID
   - **Optional**: [ ] Device binding (prevents others from using this UUID on other devices)
2. **Optional Registration**: "Claim this character" with username/password  
   - **Optional**: [✓] Enable device binding for extra security
3. **Future Logins**: Enter credentials to resume character
4. **Device Management**: Add/remove trusted devices anytime

### Device Binding Features (Optional Security Layer)
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

### Device Management Functions
```gdscript
# Toggle device binding on/off
func toggle_device_binding(username: String, enabled: bool):
    if username in accounts:
        accounts[username]["device_binding_enabled"] = enabled
        if enabled and get_device_fingerprint() not in accounts[username]["trusted_devices"]:
            accounts[username]["trusted_devices"].append(get_device_fingerprint())
        save_accounts()

# Add new trusted device (requires password confirmation)
func add_trusted_device(username: String, password: String) -> bool:
    if login_simple_account(username, password) != "":
        var device_fp = get_device_fingerprint()
        if device_fp not in accounts[username]["trusted_devices"]:
            accounts[username]["trusted_devices"].append(device_fp)
            save_accounts()
            return true
    return false
```

### Use Cases
- **🏠 Home Computer**: Enable device binding for security
- **🎮 Gaming Café**: Disable device binding for flexibility  
- **💻 Work/School**: Add trusted device temporarily
- **📱 Mobile**: Cross-platform play without device restrictions

## Phase 3 - Steam Integration (FUTURE)

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

## Phase 4 - Advanced Features (FUTURE)

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

### Phase 3 (Steam Integration)
1. Steam SDK integration
2. Steam ID verification
3. Visual verification system
4. Steam friend invitations
5. Achievement system

### Phase 4 (Advanced Features)
1. Multi-platform OAuth
2. Account recovery system
3. Two-factor authentication
4. Session management
5. Cross-platform sync

## Security Philosophy

### "Progressive Trust" Model
1. **Anonymous** → Instant play, no barriers (UUID only)
   - Optional: [ ] Device binding for anonymous UUID protection
2. **Simple Account** → Username + password, cross-device access  
   - Optional: [✓] Enable device binding (recommended)
   - Optional: [ ] Remember login on this device
3. **Steam Verified** → High trust, cross-platform features
4. **Multi-Factor** → Maximum security, valuable accounts

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