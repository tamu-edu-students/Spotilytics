# 🎧 Spotilytics 2.0

Spotilytics is a Ruby on Rails web application that connects to the Spotify Web API to generate an on-demand “Spotify Wrapped” experience.
Users can log in with their Spotify account to instantly view their Top Tracks, Top Artists, Genre insights, Mood Dashboard, Listening Patterns and a lot more.

The app uses Spotify OAuth 2.0 authentication via the official Spotify Developer APIs and all data is fetched directly from Spotify in real time.

---

## Useful URLs

- **Heroku Dashboard:** [https://spotilytics-v2-df4cb8734a44.herokuapp.com/home](https://spotilytics-v2-df4cb8734a44.herokuapp.com/home)
- **GitHub Projects Dashboard:** [https://github.com/orgs/tamu-edu-students/projects/183](https://github.com/orgs/tamu-edu-students/projects/183)
- **Burn up chart** [https://github.com/orgs/tamu-edu-students/projects/183/insights](https://github.com/orgs/tamu-edu-students/projects/183/insights)
- **Slack Group** (to track Scrum Events) - #csce606-proj2-group1 - [https://tamu.slack.com/archives/C09SF9LJ6TT](https://tamu.slack.com/archives/C09SF9LJ6TT)

## Features

Spotilytics V1 had the following features:

1. Login securely using Spotify OAuth 2.0 authentication
2. Personalized Dashboard showing:
   - Top Tracks of the Year
   - Top Artists of the Year
   - Top Genres (with interactive pie chart visualization)
   - Followed Artists list with direct Spotify links
3. Dynamic Top Tracks and Top Artists display including:
   - Artist images, track name, artist(s), album name, and popularity score
   - Three time ranges — Last 4 Weeks, Last 6 Months, and Last 1 Year
   - Options to view Top 10, Top 25, or Top 50 tracks
   - “Play on Spotify” buttons linking directly to each track
4. Artist Follow/Unfollow feature:
5. Genre Analytics:
   - Auto-generated pie chart summarizing top genres
   - Visual breakdown of listening distribution (e.g., Pop, Indie, Hip-Hop, etc.)
6. Playlist Creation:
   - Create new Spotify playlists from your top tracks for any time range
   - Automatically name and describe playlists (e.g., “Your Top Tracks – Last 6 Months”)

Adding on top of the first version of Spotiliytics we have the following features:

1. Database Caching for Top Tracks & Top Artists

   - The app stores the user’s top tracks and artists in a local database.
   - Prevents excessive Spotify API calls and significantly improves load time.
   - Cached data is reused until:
     - The user clicks Refresh Data or
     - Stored records become older than 4 days.

2. Refresh Data System (Manual + Automatic)

   - A “Refresh Data” button forces an immediate re-sync.
   - A background scheduler auto-refreshes user data every 4 days.
   - Dashboard always shows up-to-date listening insights.

3. Track Journey — Taste Evolution Over Time
   Shows how a user’s music preference changes over 4 weeks → 6 months → 1 year.

Tracks are categorized into: - Evergreen — Appears in all 3 ranges - New Obsession — Appears only in recent 4 weeks - Short-Term Crush — In 4 weeks + 6 months but not 1 year - Fading Out — Decreasing popularity over time

4. Listening Habit Calendar (Heatmap)

   - GitHub-style heatmap of listening frequency.
   - Shows daily listening intensity across months.
   - Uses timestamps from recently played tracks.

5. Mood Explorer — Interactive JS Dashboard

A fully interactive mood-based music explorer with the following features: - Interactive Mood Wheel (Hype, Party, Chill, Sad) - Real-time filtering of tracks by mood category - Animated radar chart micro-analysis panel that auto-updates: - Track name & artist - Feature values - Mood descriptors - Visual radar profile

6. Mood Explorer — No-JavaScript Fallback version
   For users with JS disabled: - A static Mood Navigator replaces the mood wheel. - Each track displays a “View Mood Analysis” button. Clicking opens a fully server-rendered track analysis page showing: - Audio feature values - Derived mood cluster - Track name, artist, and image

7. AI-Style Music Personality Summary

8. Playlist Energy Curve Visualization

   - Visualize the energy scores of the tracks in a give playlist

9. Listening Hours Trendline (Long-Term Visualization)

   - Showing montly listening time

10. Compare Playlist With a Friend (Overlap Score)
    - Comparing two playlists with the similarity score
    - We average energy, danceability, valence, acousticness, and instrumentalness for each playlist, then compute cosine similarity (0–100).

## Getting Started — From Zero to Deployed

Follow these steps to take Spotilytics from a fresh clone to a deployed, working application on Heroku.

### 1️⃣ Prerequisites

Make sure you have the following installed:

| Tool       | Install Command                                                   |
| ---------- | ----------------------------------------------------------------- |
| Ruby       | `rbenv install 3.x.x`                                             |
| Bundler    | `gem install bundler`                                             |
| Git        | `sudo apt install git`                                            |
| Heroku CLI | [Install guide](https://devcenter.heroku.com/articles/heroku-cli) |

---

### 2️⃣ Clone the Repository

```bash
git https://github.com/tamu-edu-students/Spotilytics-project3-team2
cd Spotilytics-project3-team2
```

---

### 3️⃣ Install Dependencies and Setup the Database

```bash
bundle install
```

```bash
# Create, migrate, and prepare test DB
rails db:migrate

# (Optional) Seed with sample users, notes and collaborations
rails db:seed
```

---

### 4️⃣ Spotify Developer Setup

To access user data, you must register the app with Spotify:

1. Go to the Spotify Developer Dashboard.
2. Create a new App.
3. Copy your:
   1. Client ID
   2. Client Secret
4. Under Redirect URIs, add:
   1. https://localhost:3000/auth/spotify/callback
   2. http://127.0.0.1:3000/auth/spotify/callback
   3. https://spotilytics-v2-df4cb8734a44.herokuapp.com/auth/spotify/callback
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

Visit: http://[127.0.0.1:3000/](http://127.0.0.1:3000/)

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
open coverage/cucumber/index.html
open coverage/rspec/index.html
```

---

### 8️⃣ Setup Heroku Deployment (CD)

#### Step 1: Create a Heroku App

```bash
heroku login
heroku create <your-app-name>  # in this case 'heroku create spotilytics'
```

#### Step 2: Add PostgreSQL Add-on

```bash
heroku addons:create heroku-postgresql:mini --app <your-app-name>
```

You can execute `git remote` to show a list of all remote Git repos associated with your app, among which heroku should now appear. You can execute `git remote show heroku` to verify that pushing to the heroku "repo" will deploy to a URL on Heroku whose name matches the name you picked for your app ('note-together').

#### Step 3: Set GitHub Secrets/ Heroku Secrets

In **GitHub** → **Settings → Secrets and Variables → Actions**, add the following secrets in Repository Secrets section:

| Secret                  | Description                                             |
| ----------------------- | ------------------------------------------------------- |
| `HEROKU_API_KEY`        | Your Heroku API key (run `heroku auth:token` to get it) |
| `HEROKU_APP_NAME`       | Your Heroku app name (spotilytics in this case)         |
| `SPOTIFY_CLIENT_ID`     | Your Spotify Client ID                                  |
| `SPOTIFY_CLIENT_SECRET` | Your Spotify Client Secret                              |

#### Step 4: DB setup and deployment:

#### Migrate Database (first deploy only)

```bash
heroku run bin/rails db:migrate --app spotilytics-v2
heroku run bin/rails db:seed --app spotilytics-v2
```

- These steps are added as worker processes in `Procfile` to avoid manually typing them after every change.
- Every time a pull request is merged into main, the app is automatically deploys to Heroku through the Github Actions workflow setup in .github/workflows/ci.yml
- You can verify deployment progress under the Actions tab in your repository.
- The deployment starts only after all the check/tests pass.

#### To manually deploy using the Heroku CLI if you’re not using GitHub Actions:

```bash
heroku run bin/rails db:migrate --app spotilytics-v2
heroku run bin/rails db:seed --app spotilytics-v2
git push heroku main
heroku open
```

### 9️⃣ Access the App

Once deployed, visit your live Heroku URL:
https://spotilytics-v2-df4cb8734a44.herokuapp.com/

You’ll be able to:

1. Log in with Spotify
2. View your top artists, tracks, dahboard, mood board and listening patterns by timeframe
3. Generate playlists from your top songs
4. Track your listening habits and how your music taste has changed over time

## Useful Commands

| **Task**                                                   | **Command**                      |
| ---------------------------------------------------------- | -------------------------------- |
| **start server**                                           | `rails server`                   |
| **run rspec tests**                                        | `bundle exec rspec`              |
| **run cucumber tests**                                     | `bundle exec cucumber`           |
| **check test coverage**                                    | `open coverage/rspec/index.html` |
| **check last few lines of error log messages from Heroku** | `heroku logs`                    |

# User Guide — Spotilytics

Welcome to Spotilytics v2, your personalized Spotify analytics dashboard!
Spotilytics lets you view your listening history, track your music journey and listening pattern, view your top artists and tracks and also compare your playlist with that of a friend anytime - like having Spotify Wrapped on demand.

---

### Getting Started

1. **Access the App**  
   Visit your deployed app [https://spotilytics-v2-df4cb8734a44.herokuapp.com/](https://spotilytics-v2-df4cb8734a44.herokuapp.com/)

   Requirements

   - A Spotify account (Free or Premium)
   - Internet connection and a browser
   - Permission to connect Spotilytics to your Spotify account

2. **Logging In with Spotify**

   1. Visit the Spotilytics home page.
   2. Click “Log in with Spotify”.
   3. You’ll be redirected to Spotify’s secure authorization page.
   4. Click “Agree” to give Spotilytics access to:
      - Your top tracks and artists
      - Permission to create playlists on your behalf
   5. You’ll be redirected back to the Home Page once authentication succeeds.

   Spotilytics uses Spotify OAuth 2.0, so:

   - Your credentials are never stored by us.
   - Only temporary tokens are used per session.
   - Tokens automatically expire for security.

3. **Home Page Overview**

   After logging in, you’ll see the Home Page featuring: - The Spotilytics logo and Spotify branding - A short description of what the app does - A “My Dashboard”, "Mood Explorer" button that takes you to your personalized analytics
   This page acts as your entry point to explore your listening statistics.

4. **Dashboard Overview**

   Your dashboard provides a snapshot of your listening habits.
   It’s divided into four main sections:

   _Top Tracks This Year_

   - Displays your most-listened-to songs over the past year.

   _Top Artists This Year_

   - Displays your most-played artists this year.

   _Top Genres_

   - A pie chart visualization of your most-listened-to genres.
   - The chart includes both major genres and an “Other” category for lesser-played types.

   _Followed Artists & New Releases_

   - Lists artists you follow on Spotify, with profile images and “View on Spotify” links.
   - Shows recent releases from your favorite artists.

5. **Mood Explorer Overview**

   The Mood Explorer helps you understand how your top songs feel based on their audio features — Energy, Valence, Danceability, Tempo, and Acousticness.
   It’s divided into three interactive sections:

   A. Mood Navigator

   - A visual mood wheel that groups songs into emotional categories such as Hype, Party, Chill, and Sad.
   - Tap any segment to instantly filter your songs by that mood.
   - Tap again to reset and view all tracks.

   B. Mood-Mapped Song List

   - Shows your Top 10 tracks, automatically clustered based on emotional similarity.
   - Each song card displays:
     - Track name, artist(s), and album art
     - Key mood metrics (Energy & Danceability)
     - Assigned mood label
   - Selecting a song updates the Micro-Analysis panel on the right.

   C. Micro-Analysis Panel

   - Provides a detailed breakdown of the selected track using a radar (spider) chart.
   - Visualizes five emotional/audio attributes:
     - Energy
     - Danceability
     - Valence
     - Acousticness
     - Tempo

6. **Top Tracks & Top Artists Page**

   Navigate to Top Tracks & Top Artists using the navigation bar or via the dashboard.

   This page lets you view your top tracks and top artists over different time periods.

   _Time Ranges_:

   - Last 4 Weeks
   - Last 6 Months
   - Last 1 Year

   _Adjustable Limits_:

   Use the dropdown menu under any of the time range to switch between:

   - Top 10
   - Top 25
   - Top 50

   Your results update automatically when you change the selection.

   Follow / Unfollow Artists

   - Next to each artist, you’ll see a Follow / Unfollow button.
   - Click to modify your followed artists directly through Spotilytics.
   - Changes reflect instantly in your Spotify account.

7. **Listening Pattern Page**

   The Listening Pattern page uncovers your daily listening habits by analyzing timestamps from your recent Spotify history. The system groups your plays by hour of the day (in UTC) and visualizes them with a histogram, showing exactly when you tend to hit play—morning commutes, afternoon focus sessions, evening wind-downs etc

   A “Your Peaks” panel summarizes your top three listening hours, helping you quickly identify the times of day when you are most active musically.

8. **Monthly Hours**

   The Monthly Listening dashboard visualizes how many hours of music a user has listened to each month based on their Spotify Recently Played history. The page fetches the most recent track plays, sums their durations by calendar month and displays the results using a clear bar-chart visualization. This feature provides a simple, data-driven look at changing listening habits over time.

9. **Music Personality**

   The Music Personality page analyzes a user’s listening patterns and audio features to generate a personalized identity that reflects their overall vibe and listening behavior. The page highlights key mood tags, provides a short personality summary, and showcases example tracks that match the user’s musical style. It helps users understand not just what they listen to, but who they are as a listener.

10. **Recommendations Page**

    The Recommendations tab generates personalized music recommendations based on your recent listening history and top artists.

    What You’ll See:

    - A curated grid of recommended tracks and albums.

---

### Tips for Best Use

- Use “Refresh Data” button on the nav bar after major listening changes (e.g. a new playlist binge) to see updated top tracks instantly.
- Review the Listening Pattern graphs weekly to spot trends (e.g., rising artists, shifting genres, repeat-heavy weeks).
- Use the genre distribution chart to understand your dominant listening moods and how they change over time.
- In Mood Explorer, click tracks to reveal their emotional profile and identify the mood clusters you gravitate toward.
- Filter by a mood (Hype, Chill, Sad, Party) to discover what kind of energy your recent listening reflects.
- Try selecting different songs — the micro-analysis panel updates instantly with deeper feature insights (energy, valence, acousticness, tempo).
- Explore Recommendations often — they’re dynamically personalized based on your recent activity and top artists.

---

### Troubleshooting Guide

- Login issues? -> Log out, clear your browser cache, then log back in via Spotify.
- Data not updating? -> Click Refresh Data or revoke and reauthorize the app in your Spotify account settings.
- Blank dashboard or missing stats? -> Ensure your Spotify account has at least a few weeks of listening history.
- Playlist creation failing? -> Check that your Spotify session hasn’t expired — re-login to fix this instantly.

---

# Architecture Decision Records (ADRs)

## ADR 0001 – Authentication via Spotify OAuth

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

## ADR 0002 – Short-Lived Caching in Memory/Session

**Status:** Accepted

**Context**  
Originally, Spotify API responses were cached briefly in memory/session to reduce API usage and improve page performance.
However, this cache was volatile—lost on dyno restarts—and provided no persistence or historical visibility.
Rate limits and repeated API calls remained a concern.

**Decision**  
Move caching from in-memory/session storage to a local database–backed caching layer.
Each dataset (Top Tracks, Top Artists, New Releases, Followed Artists, Search Results, etc.) is now persisted in dedicated tables.
Every fetch stores a “batch” with spotify_user_id, parameters (limit, time_range), and fetched_at.
On subsequent requests, the system returns cached DB rows if they remain within the defined max_age window.
Users can manually trigger a “Refresh Data” action to invalidate cached entries and force new API calls.

Advantages:

- Cached data now persists across dyno restarts
- Significant reduction in repeated Spotify API calls
- Much faster page load times for heavy views (Top Tracks, Top Artists, Mood Explorer, etc.)
- Supports historical debugging, as batches can be inspected
- Provides a more reliable foundation for advanced features (Mood Explorer, Track Journey)

Downsides:

- Local DB grows over time; requires occasional cleanup
- Slightly higher storage and ORM overhead compared to session caching
- Potential for stale data if refresh intervals are too long (mitigated via max_age + manual refresh)

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

## ADR 006 - Add Mood Explorer Using External Audio-Features API

**Status:** Accepted

**Context**
Spotify deprecated the original /audio-features endpoint for external use.
To visualize emotional characteristics of music (energy, valence, danceability, acousticness), we needed an alternative data source.
The ReccoBeats API provides audio-feature vectors compatible with Spotify track IDs.

**Decision**
Implement a Mood Explorer feature with two layers:

1. Mood Clustering

- Fetch audio features for the user’s Top 10 tracks via ReccoBeats
- Classify songs into predefined moods (Hype, Party, Chill, Sad, Aggressive)
- Display them in an interactive layout

2. Micro-Analysis Panel

- When a song is selected, show a radar chart visualizing its emotional profile
- Provide descriptive mood tags and a clean UI for deep inspection

Fallback:

- When JavaScript is disabled, users can still view per-track mood analysis via a server-side “View Mood Analysis” page.

**Consequences**
Advantages:

- Restores audio-feature analysis even after Spotify API deprecation
  - Engaging, highly interactive UI with mood filtering and radar charts
  - Works even without JavaScript (SSR fallback)

Downsides:

- External API dependency → adds latency & potential failure modes
  - Mood classifications are heuristic and may not match user perception
  - Requires maintaining consistent mapping between Spotify IDs and ReccoBeats IDs

---

# Postmortem:

## Incident 001 – Limited User Data for Inactive Spotify Accounts

Date: 2025-28-11
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

## Incident 002 – Restricted Access in Spotify Developer “Development Mode”

Date: 2025-25-11
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

## Incident 003 – Mood Explorer Not Rendering on First Load

Date: 2025-01-12
Status: Closed

### Impact

Users reported that the Mood Explorer page appeared blank or partially loaded when accessed for the first time. The mood wheel, radar chart, and track cards did not initialize until the page was manually refreshed. This created confusion and made users believe the feature was malfunctioning.

### Root Cause

The interactive components in Mood Explorer relied on DOM elements that were not fully available when JavaScript initialized. Turbo (Rails’ default navigation system) was caching and reusing partial page loads, causing event listeners and Chart.js to attach before the track data was present.

### Actions Taken

- Disabled Turbo for the Mood Explorer route (data: { turbo: false }) to force a full page render.
  - Added JavaScript guards to prevent initialization when elements are missing and retry when the DOM stabilizes.
  - Reworked the track card rendering to ensure JS can safely attach listeners on first load.

### Follow-Up

- Evaluate adding Turbo-compatible JS initialization using turbo:load events.
- Consider preloading minimal mood metadata server-side for faster perceived load.

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

| Issue / Area                                                              | Tried Solutions                                                    | Final Working Fix / Recommendation                                                                                                                                                                                                                                                                 |
| ------------------------------------------------------------------------- | ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Spotify OAuth login failing (“invalid_client” or “redirect_uri_mismatch”) | Tried re-authenticating and restarting server — didn’t help.       | Added the exact callback URLs (/auth/spotify/callback) for both localhost and Heroku to the Spotify Developer Dashboard and verified SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET were set in GitHub Actions and Heroku config vars. Also ensured that the user was whitelisted in development mode |
| Empty dashboard for inactive Spotify users                                | Tried switching to long_term time range only - data still missing. | Added friendly empty-state messages when Spotify returns insufficient top tracks/artists.                                                                                                                                                                                                          |
| Playlist creation failing with “Invalid time range”                       | Tried re-sending POST requests from UI — no success.               | Ensured time_range parameter matches one of the valid keys: short_term, medium_term, long_term.                                                                                                                                                                                                    |
| Recommendations tab returning no results                                  | Verified API keys — still empty.                                   | Confirmed the app had user-top-read and user-read-recently-played scopes enabled in Spotify Developer Dashboard                                                                                                                                                                                    |
| Top Tracks limits not persisting across columns                           | Only the changed column updated — others reset to default.         | Preserved other range limits via hidden fields (limit_short_term, limit_medium_term, limit_long_term) in the form before submission.                                                                                                                                                               |

---

# Debugging Common Issues

| Problem                        | Likely Cause                                        | Fix                                                                                                                                       |
| ------------------------------ | --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- |
| OAuth callback fails on Heroku | Missing redirect URI or wrong environment variables | Add exact production callback to Spotify Developer Dashboard and check SPOTIFY_CLIENT_ID / SPOTIFY_CLIENT_SECRET in Heroku/ Github config |

| “You are not registered for this app” during login / Login works locally but not in production
| Spotify app still in Development Mode | Add test users under User Management in Spotify Dashboard or request Production access |
| Follow/Unfollow buttons randomly fail | Rate limit hit | Batch or throttle API requests; respect Spotify’s rate limits; avoid repeated clicks |

# Summary

**Spotilytics** lets Spotify users:

- Dive into year-round listening insights, similar to Spotify Wrapped but fully customizable
- View top tracks, top artists, and top genres across multiple time ranges (4 Weeks, 6 Months, 1 Year)
- Explore moods in depth using the interactive Mood Explorer and Micro-Analysis Radar Panel
- Get insights highlighting peak listening periods and habits
- Get personalized smart recommendations powered by listening history and cached Spotify data
- Create and save custom Spotify playlists based on top tracks from any time range
- Visualizes how a playlist’s energy builds, drops, and flows across the track sequence
- Understand your “music personality” based on your listening data
- Share playlists and compare music tastes with friends through playlist-based similarity features

# Developed by Team 2 - CSCE 606 (Fall 2025)

## Team Members

- **Spoorthy Kumbashi Raghavendra**
- **Cameron Yoffe**
- **Charlie Chiu**
- **Venkateshwarlu Nagineni**

> “Discover Your Sound”
