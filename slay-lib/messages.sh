#!/usr/bin/env bash
# slay-lib/messages.sh - Greetings, spinners, and escalating wait messages

# Random spinner picker
SPINNERS=("line" "dot" "minidot" "jump" "pulse" "points" "globe" "moon" "monkey" "meter" "hamburger")
random_spinner() {
    echo "${SPINNERS[$RANDOM % ${#SPINNERS[@]}]}"
}

# Random Kardashian-style greeting
GREETINGS=(
    "She's ready. Pick a project. 💅"
    "Okay so like... which one?"
    "The vibes are immaculate. Choose."
    "You're doing amazing, sweetie. Now pick."
    "It's giving... options."
    "Main character energy. Pick your moment."
    "Bible. These projects need you."
    "The projects are projecting. Choose wisely."
    "Not me being obsessed with all of these."
    "This is YOUR moment. Own it."
    "Manifesting the right choice for you..."
    "Like, literally just pick one."
    "The repos are gathered, your honor."
    "Choose your fighter, bestie."
    "Not the decision paralysis at 3pm..."
    "Every project is rooting for you rn."
    "The cursor is hovering. The destiny awaits."
    "You walked in like the Kim of code. Pick something."
    "She's serving 'pick me' energy. Multiple shes."
    "The directory has spoken. Now you speak."
    "It's a vibe. It's a moment. It's a project picker."
    "Don't keep them waiting, queen."
    "Honestly? Any of these would be lucky."
    "Manifesting productivity. Pick to begin."
)
random_greeting() {
    echo "${GREETINGS[$RANDOM % ${#GREETINGS[@]}]}"
}

# Sassy messages for when you're caught on a rogue branch
ROGUE_BRANCH_SASS=(
    "On some other journey to self-fulfillment, bish? 💅"
    "Living your feature branch fantasy, I see..."
    "Not the side quest when main plot is calling..."
    "The audacity to be on a different timeline rn..."
    "She's off-brand, off-grid, off-master..."
    "This branch is giving 'soft launch' energy."
    "Not you cosplaying as a different developer..."
    "The HEAD detached and so did your decision-making."
)
random_rogue_branch_sass() {
    echo "${ROGUE_BRANCH_SASS[$RANDOM % ${#ROGUE_BRANCH_SASS[@]}]}"
}

# Hotfix-ready celebration messages
HOTFIX_READY=(
    "You're ready to slay that hotfix, bestie 💅"
    "Main branch energy ACTIVATED. Go fix that bug, queen."
    "She's synced, she's ready, she's about to save the day."
    "The hot in hotfix is YOU right now. Get it done."
    "You didn't come this far to only come this far. Ship it."
    "Bug? Fixed. Branch? Synced. You? Iconic."
    "This is your 'I'm about to save production' moment."
    "Kim would be proud. Now go break... I mean FIX things."
    "The repo is ready. The code is calling. Answer her."
    "Dolly Parton voice: Working 9 to 5 on this hotfix~"
    "Master is master and YOU are the moment."
    "Production is shaking. You are unbothered."
    "Every commit is a love letter to uptime, sweetie."
    "Khloé voice: that bug is GONE gone, like exes."
    "She's caught up, she's centered, she's about to ship."
    "The diff is dieffing. Push it like you mean it."
    "Pre-flight check: vibes ✅ branch ✅ caffeine ✅"
    "You are the patch we've all been waiting for."
    "Stage. Commit. Push. That's the trinity."
    "This hotfix is giving 'main character finale episode'."
)
random_hotfix_ready() {
    echo "${HOTFIX_READY[$RANDOM % ${#HOTFIX_READY[@]}]}"
}

# Kourtney-style messages for when you're WAY behind (5+ commits)
VERY_BEHIND_SASS=(
    "Girl you have NOT been checking the group chat..."
    "Giving very much 'I don't even know what day it is' energy..."
    "You've been on your own Kourtney-style journey I see..."
    "Not you being fully disconnected from the main timeline..."
    "This is giving 'didn't read the family group text for a week'..."
    "Living in your own Poosh-branded reality over here..."
    "The way you've been in your own little world... iconic but concerning."
    "You really said 'I'll check in when I check in' huh?"
    "Very 'I have better things to do than keep up' of you..."
    "Someone's been too busy living their best life to pull..."
    "The main branch has been through several eras without you..."
    "Bestie this repo has been going through IT and you missed all the tea..."
    "Babe, the repo had a whole arc. Multiple. You missed it."
    "Origin/main has aged a lifetime since you last looked..."
    "Not you treating 'git pull' like an optional spa treatment..."
    "The commits been COMMITTING. You been... where exactly?"
    "Whole storylines unfolded while you were on PTO from main..."
    "This is giving 'logged off after the tutorial' energy..."
    "You've been ghosting origin like it owes you money..."
    "There has been DEVELOPMENT, sweetie. With a capital D."
    "A whole season of the repo aired without you watching..."
    "The tree grew, the branches branched, you napped..."
    "Everyone got receipts except you, who didn't pull..."
    "This branch is so behind it's giving 'time capsule' chic..."
)
random_very_behind_sass() {
    echo "${VERY_BEHIND_SASS[$RANDOM % ${#VERY_BEHIND_SASS[@]}]}"
}

# Waiting messages - escalating energy based on elapsed time
# Note: These are initialized later after TARGET_VERSION is set
init_wait_messages() {
    local target_display="v$TARGET_VERSION"
    if [ "$TARGET_VERSION" = "__ANY_CHANGE__" ]; then
        target_display="a new version"
    fi

    WAIT_CHILL=(
        "Manifesting $target_display into existence..."
        "Waiting for $target_display to enter the chat..."
        "The deploy is deploying..."
        "Checking if anything has changed yet..."
        "Watching and waiting, bestie..."
        "Sipping tea while $target_display gets dressed..."
        "She's en route. ETA: vibes."
        "Soft polling, soft launching, soft girl summer..."
        "The pipeline is pipelining. We love that for it."
        "Hanging out at the endpoint like it's a coffee shop..."
    )

    WAIT_ANTSY=(
        "Still waiting... patience is a virtue or whatever..."
        "Loading... please hold..."
        "Any minute now... allegedly..."
        "The version will version when it versions..."
        "She's taking her time and that's okay I guess..."
        "Tapping foot in 4/4 time over here..."
        "Counting ceiling tiles while CI does its thing..."
        "Not the deploy taking longer than my last relationship..."
        "Checking my watch. Checking yours. Checking the deploy."
        "This is the DMV but for code..."
    )

    WAIT_UNHINGED=(
        "HELLO?! WHERE IS THE NEW VERSION?!"
        "I am LOOKING... respectfully..."
        "The way I'm STARING at this endpoint rn..."
        "Not me refreshing like my life depends on it..."
        "This deploy is testing my patience fr fr..."
        "This is giving 'waiting for a text back' energy..."
        "I've been here for MINUTES. PLURAL."
        "The audacity of this version to not be here yet..."
        "BABE. THE DEPLOY. WHERE."
        "I will NOT be ignored by a CI/CD pipeline."
        "Polling so hard the endpoint filed a restraining order..."
        "Is the server okay?? Is anyone okay?? Am I okay??"
        "The five stages of grief but all of them are 'still waiting'..."
        "I am UNWELL about this deploy..."
        "Production owes me an apology AND a new version..."
        "Crashing OUT over a HEAD request..."
    )
}

# Verify messages
VERIFY_MESSAGES=(
    "Ooh spotted it! Double-checking she's stable..."
    "Wait is that her?! Verifying..."
    "Version match detected! Confirming it's not a flicker..."
    "She might be here! Let me make sure..."
    "HOLD ON - is this real?! Checking..."
    "Squinting at the response headers like 'IS that you?'..."
    "Receipts requested. Verifying authenticity..."
    "Could be the new version. Could be a mirage. Investigating..."
    "Doing a vibe check on this version before we celebrate..."
    "Not getting catfished by a stale cache today, thanks..."
)

get_random_chill() {
    echo "${WAIT_CHILL[$RANDOM % ${#WAIT_CHILL[@]}]}"
}

get_random_antsy() {
    echo "${WAIT_ANTSY[$RANDOM % ${#WAIT_ANTSY[@]}]}"
}

get_random_unhinged() {
    echo "${WAIT_UNHINGED[$RANDOM % ${#WAIT_UNHINGED[@]}]}"
}

get_random_verify() {
    echo "${VERIFY_MESSAGES[$RANDOM % ${#VERIFY_MESSAGES[@]}]}"
}
