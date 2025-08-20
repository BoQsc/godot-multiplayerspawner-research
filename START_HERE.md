# 🎮 Godot Multiplayer Spawner Research

**What this project does:** Explores how to properly spawn and manage players in Godot multiplayer games.

## 🚀 Quick Start

**Run the game:**
- **Server**: Run with `--server` argument  
- **Client**: Run normally to connect as client
- **Custom IP**: Press F3 in-game to connect to specific server

**Controls:**
- Arrow keys: Move
- Space: Jump  
- F1: Device binding settings
- F2: Registration/login
- F4: Player list

## 📁 Project Structure

### Core Game Systems
- `game_manager.gd` - Main multiplayer coordination
- `network_manager.gd` - Network synchronization  
- `world_manager.gd` - World state management
- `entity_scene.gd` - Player character behavior

### Player Identity System  
- `player_accounts/` - User registration and login
- `user_identity.gd` - Player identity management

### Game Content
- `game_world/` - World scenes and data
- `art/` - Visual assets and sprites
- `tools/` - Development utilities and plugins

### Project Info
- `research/` - Analysis and findings about the multiplayer system
- `builds/` - Compiled game executables

## 🎯 What You'll Learn

This project demonstrates:
- **Player spawning** - How players join and appear in the world
- **Identity management** - Persistent player accounts across sessions  
- **Network synchronization** - Smooth multiplayer movement
- **World persistence** - Saving player progress and world changes

## 🔧 Current Status

✅ **Working**: Player spawning, networking, world persistence  
🚧 **Missing**: NPCs, AI entities, advanced gameplay features

---
*Ready to explore? Check the `research/` folder for detailed analysis!*