// Ensure AWS Cognito SDK is loaded first
if (typeof AmazonCognitoIdentity === 'undefined') {
    console.error("AmazonCognitoIdentity SDK is not loaded. Check your script imports.");
}

// AWS Configuration
const PROFILE_API     = "__PROFILE_API_URL__";
const region          = "ap-southeast-1";
const identityPoolId = "__IDENTITY_POOL_ID__";
const userPoolId      = "__USER_POOL_ID__";
const clientId        = "__COGNITO_CLIENT_ID__";
const COGNITO_DOMAIN = "__CUSTOM_COGNITO_DOMAIN__";

// Set up Cognito User Pool
let userPool;
if (typeof AmazonCognitoIdentity !== 'undefined') {
    const poolData = { UserPoolId: userPoolId, ClientId: clientId };
    userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);
}

if (typeof AWS !== 'undefined') {
    AWS.config.update({
        region: region,
        credentials: new AWS.CognitoIdentityCredentials({
            IdentityPoolId: identityPoolId
        })
    });
}

// DOM Elements
const profilePic = document.getElementById('profilePic');
const uploadStatus = document.getElementById('uploadStatus');
const fileInput = document.getElementById('fileInput');
const uploadBtn = document.getElementById('uploadBtn');

let selectedFile = null;

// ==============================================================================
// 🛠️ URL SAFEGUARD ENGINE: Prevents naked domain 404/CORS/405 errors
// ==============================================================================
function getCleanProfileUrl() {
    if (PROFILE_API.startsWith('__')) {
        return '/profileimagetos3';
    }
    const baseClean = PROFILE_API.replace(/\/$/, '');
    return baseClean.endsWith('/profileimagetos3') ? baseClean : `${baseClean}/profileimagetos3`;
}

const showMessage = (message, isError = false) => {
    uploadStatus.style.display = 'block';
    uploadStatus.className = 'status-message show';
    uploadStatus.style.backgroundColor = 'transparent'; 
    uploadStatus.style.color = isError ? 'red' : 'green';
    uploadStatus.textContent = message;

    setTimeout(() => {
        uploadStatus.classList.remove('show');
        setTimeout(() => {
            uploadStatus.textContent = '';
            uploadStatus.style.display = ''; 
        }, 300); 
    }, 3000);
};

function displayImagePreview(file) {
    const reader = new FileReader();
    reader.onload = () => { profilePic.src = reader.result; };
    reader.readAsDataURL(file);
}

async function fetchUserProfile() {
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) throw new Error('No authentication data found.');

        const payload = JSON.parse(atob(authToken.split('.')[1]));
        const userData = {
            username: payload['cognito:username'],
            email: payload.email
        };
        localStorage.setItem('cognitoUser', JSON.stringify(userData));

        document.getElementById("username").textContent = userData.username;
        document.getElementById("email").textContent = userData.email;
    } catch (error) {
        console.error('Profile Error:', error);
        showMessage("Redirecting to login...", true);
        setTimeout(() => { window.location.href = "index.html"; }, 2000);
    }
}

// Updated Upload Handler
async function handleFileUpload(file) {
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) {
            showMessage("User not authenticated. Please login again.", true);
            return;
        }

        const payload = JSON.parse(atob(authToken.split('.')[1]));
        const username = payload['cognito:username'];
        const requestBody = { username };

        showMessage("Uploading...", false);

        // 🎯 SAFEGUARD ENGINE: Dynamically maps request targets
        const targetUrl = getCleanProfileUrl();

        const response = await fetch(targetUrl, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": `Bearer ${authToken}` // Aligned for API Gateway v2 compatibility
            },
            body: JSON.stringify(requestBody)
        });

        const data = await response.json();
        if (!data.uploadUrl) {
            showMessage("Failed to get upload URL", true);
            return;
        }

        // 🎯 FIXED: Header matching for the Cache-Control bypass strategy
        const uploadRes = await fetch(data.uploadUrl, {
            method: "PUT",
            headers: { 
                "Content-Type": "image/jpeg",
                "Cache-Control": "max-age=0, must-revalidate, no-cache" // 🎯 Tell S3 to mark this file as non-cacheable
            },
            body: file
        });

        if (!uploadRes.ok) {
            showMessage("Upload to S3 failed", true);
            return;
        }

        showMessage("Profile Picture uploaded successfully!", false);
        
        // 🎯 1. Set a persistent update flag in localStorage with a unique timestamp
        const uploadTimestamp = new Date().getTime();
        localStorage.setItem(`profile_update_${username}`, uploadTimestamp);

        // 🎯 2. Force load the new image instantly using the fresh timestamp
        await fetchProfilePicture(uploadTimestamp); 
    } catch (error) {
        console.error("Upload Error:", error);
        showMessage("Upload failed", true);
    }
}

// 🎯 FIXED DESIGN: High-speed, network-decoupled Profile Picture Loading (Console Safe)
async function fetchProfilePicture(forcedTimestamp = null) {
    const profilePic = document.getElementById("profilePic");
    const navProfilePic = document.getElementById("navProfilePic"); 
    const defaultImage = "images/default-profile.png";
    
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) {
            if (profilePic) profilePic.src = defaultImage;
            if (navProfilePic) navProfilePic.src = defaultImage;
            return;
        }
        
        const payload = JSON.parse(atob(authToken.split('.')[1]));
        const username = payload['cognito:username'];
        if (!username) {
            if (profilePic) profilePic.src = defaultImage;
            if (navProfilePic) navProfilePic.src = defaultImage;
            return;
        }

        let finalUrl = `https://baylenweb-app.xyz/profiles/${username}.jpg`;
        
        // 🎯 Smart Cache Buster Engine
        if (forcedTimestamp) {
            // Case A: Just completed a new upload write action. Grab it immediately.
            finalUrl += `?t=${forcedTimestamp}`;
        } else {
            // Case B: Regular Page Initial load. Check if user updated their picture in a previous session.
            const lastUpdate = localStorage.getItem(`profile_update_${username}`);
            if (lastUpdate) {
                finalUrl += `?t=${lastUpdate}`; // Keeps loading the updated image securely from CDN cache
            } else {
                // Case C: Absolute first load. Use a stable hour-based cache key so CloudFront caches it cleanly.
                const hourlyKey = new Date().getHours(); 
                finalUrl += `?t=${hourlyKey}`;
            }
        }
        
        // Setup Native Fallbacks (Bypasses slow, round-trip JavaScript HEAD request pre-checks)
        if (profilePic) {
            profilePic.onerror = function() {
                profilePic.src = defaultImage; // Fail silently over to fallback image without logging console errors
            };
            profilePic.src = finalUrl;
        }

        if (navProfilePic) {
            navProfilePic.onerror = function() {
                navProfilePic.src = defaultImage;
            };
            navProfilePic.src = finalUrl;
        }
        
    } catch (error) {
        console.error("Fetch error:", error);
        if (profilePic) profilePic.src = defaultImage;
        if (navProfilePic) navProfilePic.src = defaultImage;
    }
}

// Logout Handler
document.getElementById("logoutBtn").addEventListener("click", () => {
    const logoutUri = "__LOGOUT_URI__";
    window.location.href = `https://${COGNITO_DOMAIN}/logout?client_id=${clientId}&logout_uri=${encodeURIComponent(logoutUri)}`;
});

fileInput.addEventListener("change", async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    if (!file.type.startsWith('image/')) {
        showMessage("Only image files are allowed", true);
        return;
    }
    if (file.size > 5 * 1024 * 1024) {
        showMessage("File size must be less than 5MB", true);
        return;
    }
    selectedFile = file; 
    displayImagePreview(file); 
    uploadBtn.disabled = false;
});

uploadBtn.addEventListener("click", async () => {
    if (!selectedFile) {
        showMessage("Please choose a file first", true);
        return;
    }
    await handleFileUpload(selectedFile);
});

document.addEventListener('DOMContentLoaded', async () => {
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) {
            setTimeout(() => window.location.href = "index.html", 2000);
            return;
        }
        await fetchUserProfile(); 
        await fetchProfilePicture(); 
    } catch (error) {
        console.error('Initialization error:', error);
        setTimeout(() => window.location.href = "index.html", 2000);
    }
});