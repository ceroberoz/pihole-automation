# Pi-hole Dynamic List Manager

## 🚀 Executive Summary
**Why This Exists:**  
Pi-hole's default blocklists are static, but your network traffic patterns change over time. This tool automatically analyzes your actual DNS queries to create _personalized_ allowlists and blocklists that evolve with your usage.

**Key Benefits:**  
✅ **Reduces false positives** - Whitelists domains you actually use  
✅ **Blocks new trackers** - Identifies and blocks emerging threats  
✅ **Self-optimizing** - Adapts to your changing network habits  
✅ **Lightweight** - Only maintains top 50 domains in each category  

## 🛠 Quick Start
```bash
# 1. Install
git clone https://github.com/ceroberoz/pihole-automation.git
cd pihole-automation

# 2. Run analysis (shows top domains)
./analyze_pihole_logs.sh

# 3. Apply updates
./update_lists.sh

# 4. Schedule monthly updates
(crontab -l ; echo "0 3 1 * * $(pwd)/pihole_autoupdate.sh") | crontab -
```

## 🔄 How It Works
1. ***Analyzes*** your Pi-hole query logs
2. ***Identifies*** top 50 allowed/blocked domains
3. ***Refreshes*** lists while preserving manual entries
4. ***Auto-commits*** changes to Git (optional)

## 📊 Sample Output
```bash
[Analysis Report]
Top Allowed: google.com (142 hits)  
Top Blocked: adservice.com (89 hits)  

[Update Summary]
+ Whitelisted 3 new domains  
+ Blacklisted 5 new trackers  
- Removed 2 unused entries  
```

## 🌟 Pro Tip
Run manually for 1-2 weeks before automating to fine-tune results.
