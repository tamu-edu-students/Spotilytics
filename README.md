# Spotilytics

Spotilytics is a Ruby on Rails web application that connects to the Spotify Web API to generate an on-demand “Spotify Wrapped” experience.
Users can log in with their Spotify account to instantly view their Top Tracks, Top Artists and Genre insights, all powered by live Spotify data.

The app uses Spotify OAuth 2.0 authentication via the official Spotify Developer APIs and all data is fetched directly from Spotify in real time.

---

## Useful URLs

- **Heroku Dashboard:** [https://spotilytics-app-41dbe947e18e.herokuapp.com/home](https://spotilytics-app-41dbe947e18e.herokuapp.com/home)
- **GitHub Projects Dashboard:** [https://github.com/orgs/tamu-edu-students/projects/154](https://github.com/orgs/tamu-edu-students/projects/154)
- **Burn up chart** [https://github.com/orgs/tamu-edu-students/projects/154/insights](https://github.com/orgs/tamu-edu-students/projects/154/insights)
- **Slack Group** (to track Scrum Events) - #csce606-proj2-group1 - [https://tamu.slack.com/archives/C09KM1BV4TW](https://tamu.slack.com/archives/C09KM1BV4TW)


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
| `HEROKU_APP_NAME` | Your Heroku app name (note-together in this case) |
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

