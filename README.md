# 🎧 Spotilytics

Spotilytics is a Ruby on Rails web application that connects to the Spotify Web API to generate an on-demand “Spotify Wrapped” experience.
Users can log in with their Spotify account to instantly view their Top Tracks, Top Artists and Genre insights, all powered by live Spotify data.

The app uses Spotify OAuth 2.0 authentication via the official Spotify Developer APIs and all data is fetched directly from Spotify in real time.

---

## Useful URLs

- **Heroku Dashboard:** [https://spotilytics-v2-df4cb8734a44.herokuapp.com/home](https://spotilytics-v2-df4cb8734a44.herokuapp.com/home)
- **GitHub Projects Dashboard:** [https://github.com/orgs/tamu-edu-students/projects/183](https://github.com/orgs/tamu-edu-students/projects/183)
- **Burn up chart** [https://github.com/orgs/tamu-edu-students/projects/183/insights](https://github.com/orgs/tamu-edu-students/projects/183/insights)
- **Slack Group** (to track Scrum Events) - #csce606-proj2-group1 - [https://tamu.slack.com/archives/C09SF9LJ6TT](https://tamu.slack.com/archives/C09SF9LJ6TT)


## Features
1. Login securely using Spotify OAuth 2.0 authentication and fetch live Spotify data directly via the Spotify Web API
2. Personalized Dashboard showing:
    - Top Tracks of the Year
	- Top Artists of the Year
	- Top Genres (with interactive pie chart visualization)
	- Followed Artists list with direct Spotify links
3. Dynamic Top Tracks display including:
	- Rank, track name, artist(s), album name, and popularity score
	- Three time ranges — Last 4 Weeks, Last 6 Months, and Last 1 Year
	- Options to view Top 10, Top 25, or Top 50 tracks
	- “Play on Spotify” buttons linking directly to each track
4. Dynamic Top Artists view including:
	- Artist images, names, and play counts
	- Three time ranges — Past 4 Weeks, Past 6 Months, and Past Year
	- Rank indicators and selectable display limits (Top 10 / 25 / 50)
5. Artist Follow/Unfollow feature:
	- View your currently followed artists
	- Follow or unfollow artists directly within the Top Artists tab
	- Changes sync instantly with your Spotify account via the API
6. Genre Analytics:
	- Auto-generated pie chart summarizing top genres
	- Visual breakdown of listening distribution (e.g., Pop, Indie, Hip-Hop, etc.)
	- Groups minor genres under an “Other” category for clarity
7. Playlist Creation:
	- Create new Spotify playlists from your top tracks for any time range
	- Automatically name and describe playlists (e.g., “Your Top Tracks – Last 6 Months”)

## Getting Started — From Zero to Deployed

Follow these steps to take Spotilytics from a fresh clone to a deployed, working application on Heroku.

### 1️⃣ Prerequisites

Make sure you have the following installed:

| Tool | Install Command |
|------|------------------|
| Ruby | `rbenv install 3.x.x` |
| Bundler | `gem install bundler` |
| Git | `sudo apt install git` |
| Heroku CLI | [Install guide](https://devcenter.heroku.com/articles/heroku-cli) |

---

### 2️⃣ Clone the Repository

```bash
git clone https://github.com/tamu-edu-students/Spotilytics.git
cd Spotilytics
```

---

### 3️⃣ Install Dependencies

```bash
bundle install
```

--- 

### 4️⃣ Spotify Developer Setup

To access user data, you must register the app with Spotify:
1.	Go to the Spotify Developer Dashboard.
2.	Create a new App.
3.	Copy your:
	1. Client ID
	2. Client Secret
4.	Under Redirect URIs, add:
    1. https://localhost:3000/auth/spotify/callback
    2. http://127.0.0.1:3000/auth/spotify/callback
    3. https://spotilytics-app-41dbe947e18e.herokuapp.com/auth/spotify/callback
5. In User Management add your Name and Spotify mail ID
6. Click Save

--- 

### 5️⃣ Environment Configuration

Create a .env file in the project root to store your credentials:
```bash
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
```
Do not to commit .env files to Git

--- 

### 6️⃣ Run Locally

```bash
rails server
```

Visit: http://localhost:3000

You can log in using your Spotify mail ID which you added in User Management:
1. Click Log in with Spotify
2. Approve permissions
3. You’ll be redirected to the Home Page where you can see different tabs for Dashboard, Top Tracks and Top Artists

--- 

### 7️⃣ Run the Test Suite

#### This project uses both RSpec (for unit testing) and Cucumber (for feature/BDD testing)

**RSpec (unit & request tests):**

```bash
bundle exec rspec
```

**Cucumber (feature tests):**

```bash
bundle exec cucumber
```

**View Coverage Report (Coverage is generated after test runs):**

```bash
open coverage/index.html
```

---

### 8️⃣ Setup Heroku Deployment (CD)

#### Step 1: Create a Heroku App

```bash
heroku login
heroku create <your-app-name>  # in this case 'heroku create spotilytics'
```

#### Step 2: Set GitHub Secrets/ Heroku Secrets

In **GitHub** → **Settings → Secrets and Variables → Actions**, add the following secrets in Repository Secrets section:

| Secret | Description |
|--------|--------------|
| `HEROKU_API_KEY` | Your Heroku API key (run `heroku auth:token` to get it) |
| `HEROKU_APP_NAME` | Your Heroku app name (spotilytics in this case) |
| `SPOTIFY_CLIENT_ID` | Your Spotify Client ID |
| `SPOTIFY_CLIENT_SECRET` | Your Spotify Client Secret |

#### To manually deploy using the Heroku CLI if you’re not using GitHub Actions:
```bash
git push heroku main
heroku open
```

### 9️⃣ Access the App

Once deployed, visit your live Heroku URL:
https://spotilytics-demo.herokuapp.com

You’ll be able to:
1. Log in with Spotify
2. View your top artists and tracks by timeframe
3. Explore your genre breakdowns
4. Generate playlists from your top songs

## Useful Commands

| **Task**     | **Command** |
|----------------|------------------|
| **start server**  | `rails server` |
| **run rspec tests**    | `bundle exec rspec` |
| **run single RSpec test**    | `bundle exec rspec spec/models/note_spec.rb` |
| **run cucumber tests**    | `bundle exec cucumber` |
| **run single Cucumber scenario**    | `bundle exec cucumber features/notes.feature` |
| **check test coverage**       | `open coverage/index.html` |
| **check last few lines of error log messages from Heroku**       | `heroku logs` |

# User Guide — Spotilytics

Welcome to Spotilytics, your personalized Spotify analytics dashboard!
Spotilytics lets you view your listening history, top artists, top tracks, and genres anytime - like having Spotify Wrapped on demand.

---

### Getting Started

1. **Access the App**  
   Visit your deployed app [https://spotilytics-app-41dbe947e18e.herokuapp.com/](https://spotilytics-app-41dbe947e18e.herokuapp.com/)

   Requirements
	- A Spotify account (Free or Premium)
	- Internet connection and a browser
	- Permission to connect Spotilytics to your Spotify account

2. **Logging In with Spotify**
	1.	Visit the Spotilytics home page.
	2.	Click “Log in with Spotify”.
	3.	You’ll be redirected to Spotify’s secure authorization page.
	4.	Click “Agree” to give Spotilytics access to:
	    - Your top tracks and artists
	    - Permission to create playlists on your behalf
	5.	You’ll be redirected back to the Home Page once authentication succeeds.

    Spotilytics uses Spotify OAuth 2.0, so:
    - Your credentials are never stored by us.
    - Only temporary tokens are used per session.
    - Tokens automatically expire for security.

3. **Home Page Overview**

    After logging in, you’ll see the Home Page featuring:
        - The Spotilytics logo and Spotify branding
        - A short description of what the app does
        - A “My Dashboard” button that takes you to your personalized analytics
        This page acts as your entry point to explore your listening statistics.

4. **Dashboard Overview**

    Your dashboard provides a snapshot of your listening habits.
    It’s divided into four main sections:

    *Top Tracks This Year*
    - Displays your most-listened-to songs over the past year.
    - Shows the top 5 tracks with:
        - Rank number
        - Track name and artist
        - Album name and popularity (out of 100)

    *Top Artists This Year*
    - Displays your most-played artists this year.
    - Shows:
        - Rank and artist photo
        - Total plays count
        - Includes a “View Top Artists” button to explore more.

    *Top Genres*
    - A pie chart visualization of your most-listened-to genres.
    - The chart includes both major genres and an “Other” category for lesser-played types.

    *Followed Artists & New Releases*
    - Lists artists you follow on Spotify, with profile images and “View on Spotify” links.
    - Shows recent releases from your favorite artists, including:
        - Album art
        - Artist name
        - Track count and release date
        - Direct link to the album on Spotify

5. **Top Tracks Page**

    Navigate to Top Tracks using the navigation bar or via the dashboard.

    This page lets you view your top tracks over different time periods.

    *Time Ranges*:
    - Last 4 Weeks
    - Last 6 Months
    - Last 1 Year

    *Track Details*:

    For each time range, Spotilytics shows:
    - Song title
    - Artist name
    - Album title
    - Popularity score
    - “Play on Spotify” button

    *Adjustable Limits*:

    Use the dropdown menu under any of the time range to switch between:
    - Top 10
    - Top 25
    - Top 50

    Your results update automatically when you change the selection.

6. **Top Artists Page**

    The Top Artists page provides detailed insights into your most-played artists.

    *Time Ranges*

    You can view:
    - Past Year
    - Past 6 Months
    - Past 4 Weeks

    *Artist Details*

    Each section lists:
    - Rank (1–50)
    - Artist image and name
    - Estimated play count

    Follow / Unfollow Artists
    - Next to each artist, you’ll see a Follow / Unfollow button.
    - Click to modify your followed artists directly through Spotilytics.
    - Changes reflect instantly in your Spotify account.

7. **Playlist Creation**

    You can instantly turn your top tracks into a Spotify playlist.

    How to Create a Playlist:
    1.	Go to the Top Tracks page.
    2.	Choose a time range (e.g. “Last 6 Months”).
    3.	Click the “Create Playlist” button.
    4.	Spotilytics will:
        - Generate a new playlist in your Spotify account
        - Named like “Your Top Tracks – Last 6 Months”
        - Add your top 10 songs automatically

8. **Recommendations Page**

    The Recommendations tab generates personalized music recommendations based on your recent listening history and top artists.

    What You’ll See:
    - A curated grid of recommended tracks and albums.

    Each recommendation includes:
    - Album artwork
    - Song or album title
    - Artist name(s)
    - “Open in Spotify” button to play directly.

---

### Tips for Best Use

- Log in regularly - Refresh your Spotify connection every few days to keep recommendations and stats up to date.
- Use “Refresh Data” button on the nav bar after major listening changes (e.g. a new playlist binge) to see updated top tracks instantly.
- Try different time ranges (4 weeks / 6 months / 1 year) to compare your short-term and long-term listening trends.
- Explore Recommendations often — they’re dynamically personalized based on your recent activity and top artists.

---

### Troubleshooting Guide

- Login issues? -> Log out, clear your browser cache, then log back in via Spotify.
- Data not updating? -> Click Refresh Data or revoke and reauthorize the app in your Spotify account settings.
- Blank dashboard or missing stats? -> Ensure your Spotify account has at least a few weeks of listening history.
- Playlist creation failing? -> Check that your Spotify session hasn’t expired — re-login to fix this instantly.

---

# Architecture Decision Records (ADRs)

## ADR 0001 – Use Spotify API as the primary Source (No DB)
**Status:** Accepted

**Context**  
Spotilytics retrieves real-time Spotify data. Storing a local copy adds complexity and compliance risk without long-term benefit.

**Decision**  
Do not maintain an internal database. Fetch data directly from Spotify APIs and cache short-lived results only.

**Consequences**  
- Advantage: Always fresh and consistent data  
- Downside: Dependent on Spotify API uptime and latency  
- Downside: Must respect API rate limits

## ADR 0002 – Authentication via Spotify OAuth
**Status:** Accepted

**Context**  
Users must log in securely and authorize Spotilytics to access their profile, top tracks and artists.

**Decision**  
Implement Spotify OAuth 2.0 using `omniauth` and `rspotify`. Tokens are stored in session only; refresh handled by RSpotify.

**Consequences**  
- Advantage: Secure, proven flow  
- Advantage: Spotify-compliant token management  
- Downside: Relies on RSpotify library abstractions  
- Downside: Must handle expired sessions gracefully

## ADR 0003 – Short-Lived Caching in Memory/Session
**Status:** Accepted

**Context**  
Frequent Spotify API calls could slow page loads and hit rate limits.

**Decision**  
Cache lightweight API responses (e.g. top artists/tracks) in session or memory for minutes; invalidate via “Refresh Data”.

**Consequences**  
- Advantage: Faster user experience  
- Advantage: Fewer external API calls  
- Downside: Cache lost on dyno restart  
- Downside: Potential stale data if not refreshed

## ADR 0004 – Server-Side Playlist Creation
**Status:** Accepted

**Context**  
Creating playlists requires user tokens. Executing this client-side would expose credentials.

**Decision**  
Handle playlist creation entirely server-side within `PlaylistsController#create`.

**Consequences**  
- Advantage: Secure and auditable  
- Advantage: Simplifies frontend logic  
- Downside: Adds load to server-side  
- Downside: Must throttle to avoid hitting Spotify limits

## ADR 005 – Add “Refresh Data” Action for Live Spotify Sync
**Status:** Accepted

**Context**  
Spotilytics visualizes listening data (top tracks, artists, genres and recommendations) directly from Spotify’s Web API and stores it in the cache for several hours.  
Users often want to see their most recent stats — especially after major playlist updates or new songs played.  
We needed a lightweight mechanism to force re-fetching from the API without manual cache clearing or session resets.

**Decision**  
Add a **“Refresh Data”** button in the navigation bar that triggers a refresh of cached Spotify data.  
When clicked, it clears temporary session-level caches and re-requests data from Spotify APIs for:  
- Top tracks  
- Top artists  
- Recommendations  

**Consequences**  
- Advantage: Enables real-time Spotify data sync on demand  
- Advantage: Improves user trust and transparency (“instant refresh”)  
- Advantage: Avoids the need for background jobs or a persistent DB  
- Downside: Increases API traffic if users refresh too frequently  
- Downside: Adds minor latency (API round-trip before page render)

---

# Postmortem: 

## Incident 001 – Limited User Data for Inactive Spotify Accounts

Date: 2025-28-10
Status: Closed

### Impact

Users with low Spotify activity (e.g. few streams in the past year) saw empty or incomplete data visualizations on the Dashboard and Top Tracks/Artists pages. This led to poor user experience and confusion about whether the app was broken.

### Root Cause

Spotify’s “Top Items” endpoints return limited results when a user’s listening history is insufficient. Spotilytics didn’t account for this edge case in early builds.

### Actions Taken
- Added empty state UI (“Not enough data yet — start listening and come back!”).
- Adjusted analytics logic to gracefully render placeholders when fewer than 5 tracks or artists are returned.

### Follow-Up
- Consider hybrid display using Spotify featured playlists as filler data to enhance UI.

## Incident 002 – Follow/Unfollow Rate Limit Exceeded

Date: 2025-02-11
Status: Closed

### Impact

Frequent follow/unfollow actions in the Top Artists tab triggered Spotify API’s 429 Too Many Requests rate limit, causing temporary errors and failed interactions.

### Root Cause

The Spotify Web API enforces per-user and per-app rate limits. The UI allowed rapid toggling of follow state without throttling or batching requests.

### Actions Taken
- Batched multiple API calls server-side using short async queues.

### Follow-Up
- Evaluate caching artist follow state locally to reduce duplicate calls.
- Track API usage metrics in logs to identify peak load.

## Incident 003 – Restricted Access in Spotify Developer “Development Mode”

Date: 2025-25-10
Status: Ongoing (Known Limitation)

### Impact

New users not whitelisted in the Spotify Developer Dashboard couldn’t log in to Spotilytics, receiving “You are not registered for this app” errors.
This limited testing to a small group of manually added accounts.

### Root Cause

Spotify Developer apps in Development Mode only allow 25 registered testers.
Upgrading to “Production Mode” requires Spotify approval and organizational verification.

### Actions Taken
- Documented the testing limitation clearly in README.
- Added instructions for adding testers via Developer Dashboard.

### Follow-Up
- Move Spotilytics app to Spotify Verified Org once org-level upgrade is requested from Spotify.
- Add fallback “Demo Mode” (mock data) for public users to explore app features without Spotify login.

## Incident 004 – Coverage Reports Not Merging in CI

Date: 2025-03-11
Status: Resolved

### Impact

GitHub Actions showed 0% line coverage for Cucumber tests even though all scenarios passed locally.
This created confusion and reduced visibility into real test health.

### Root Cause

SimpleCov for Cucumber was writing to the default coverage/ folder, while RSpec wrote to coverage/rspec/.
CI didn’t collate both result sets before report upload.

### Actions Taken
- Updated features/support/env.rb to set:
```bash
    SimpleCov.command_name 'Cucumber'
    SimpleCov.coverage_dir 'coverage/cucumber'
```

- Updated CI workflow to run:
```bash
    bundle exec ruby bin/coverage_merge
```

- Verified merged report includes both RSpec and Cucumber.

---

# Debug Pointers

This section provides **useful context for developers** trying to debug issues in the codebase — including fixes that worked, workarounds that were tested and common dead ends to avoid.

| Issue / Area | Tried Solutions | Final Working Fix / Recommendation |
|---------------|----------------|------------------------------------|
|Spotify OAuth login failing (“invalid_client” or “redirect_uri_mismatch”)| Tried re-authenticating and restarting server — didn’t help. | Added the exact callback URLs (/auth/spotify/callback) for both localhost and Heroku to the Spotify Developer Dashboard and verified SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET were set in GitHub Actions and Heroku config vars. Also ensured that the user was whitelisted in development mode |
| Empty dashboard for inactive Spotify users | Tried switching to long_term time range only - data still missing. | Added friendly empty-state messages when Spotify returns insufficient top tracks/artists. |
| Playlist creation failing with “Invalid time range” | Tried re-sending POST requests from UI — no success. | Ensured time_range parameter matches one of the valid keys: short_term, medium_term, long_term. |
| Recommendations tab returning no results | Verified API keys — still empty. | Confirmed the app had user-top-read and user-read-recently-played scopes enabled in Spotify Developer Dashboard |
| Top Tracks limits not persisting across columns | Only the changed column updated — others reset to default. | Preserved other range limits via hidden fields (limit_short_term, limit_medium_term, limit_long_term) in the form before submission.|

---

# Debugging Common Issues

| Problem | Likely Cause | Fix |
|----------|---------------|-----|
| OAuth callback fails on Heroku | Missing redirect URI or wrong environment variables | Add exact production callback to Spotify Developer Dashboard and check SPOTIFY_CLIENT_ID / SPOTIFY_CLIENT_SECRET in Heroku/ Github config|
| “You are not registered for this app” during login / Login works locally but not in production
 | Spotify app still in Development Mode | Add test users under User Management in Spotify Dashboard or request Production access |
| Follow/Unfollow buttons randomly fail | Rate limit hit | Batch or throttle API requests; respect Spotify’s rate limits; avoid repeated clicks |

# Summary

**Spotilytics** lets Spotify users:
- Explore personalized listening stats and Spotify Wrapped-style insights anytime
- View top tracks, artists, and genres across different time ranges
- Get smart recommendations based on your listening patterns
- Create and save custom playlists directly to your Spotify account
- Manage your profile — including following and unfollowing artists — all in one place

# Developed by Team 1 - CSCE 606 (Fall 2025)
## Team Members
- **Spoorthy Kumbashi Raghavendra**
- **Cameron Yoffe**
- **Charlie Chiu**
- **Venkateshwarlu Nagineni**

> “Discover Your Sound”







