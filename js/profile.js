// Ensure AWS Cognito SDK is loaded first
if (typeof AmazonCognitoIdentity === 'undefined') {
    console.error("AmazonCognitoIdentity SDK is not loaded. Check your script imports.");
}

// AWS Configuration
// ✅ DYNAMICALLY INJECTED BY CODEBUILD PIPELINE VIA TERRAFORM
const PROFILE_API     = "__PROFILE_API_URL__"; // Target: https://api.${var.custom_domain_name}/profileimagetos3
const region          = "ap-southeast-1";
const identityPoolId = "__IDENTITY_POOL_ID__";
const userPoolId      = "__USER_POOL_ID__";
const clientId       = "__COGNITO_CLIENT_ID__";
const COGNITO_DOMAIN = "__CUSTOM_COGNITO_DOMAIN__";

// Set up Cognito User Pool
let userPool;
if (typeof AmazonCognitoIdentity !== 'undefined') {
    const poolData = { UserPoolId: userPoolId, ClientId: clientId };
    userPool = new AmazonCognitoIdentity.CognitoUserPool(poolData);
} else {
    console.error("AmazonCognitoIdentity SDK is missing. Ensure you included the Cognito SDK script.");
}

// Ensure AWS SDK is properly configured
if (typeof AWS !== 'undefined') {
    AWS.config.update({
        region: region,
        credentials: new AWS.CognitoIdentityCredentials({
            IdentityPoolId: identityPoolId
        })
    });
} else {
    console.error("AWS SDK is missing. Ensure you included the AWS SDK script.");
}

// DOM Elements
const profilePic = document.getElementById('profilePic');
const uploadStatus = document.getElementById('uploadStatus');
const fileInput = document.getElementById('fileInput');
const uploadBtn = document.getElementById('uploadBtn');

let selectedFile = null; // To store the file chosen by the user

// Utility function to show messages to user
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

// Function to convert file to base64 string
function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => {
            resolve(reader.result.split(',')[1]);
        };
        reader.onerror = error => reject(error);
        reader.readAsDataURL(file);
    });
}

// Function to display preview of selected image
function displayImagePreview(file) {
    const reader = new FileReader();
    reader.onload = () => {
        profilePic.src = reader.result; 
    };
    reader.readAsDataURL(file);
}

// Function to fetch and display user profile details using the stored auth token
async function fetchUserProfile() {
    try {
        console.log("Fetching user profile...");
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
        console.log("User profile loaded:", userData);
    } catch (error) {
        console.error('Profile Error:', error);
        showMessage("Redirecting to login...", true);
        setTimeout(() => {
            window.location.href = "index.html";
        }, 2000);
    }
}

// Simplified Upload Handler using API Gateway & Lambda
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

        // Step 1: Get presigned PUT URL using dynamic PROFILE_API
        const response = await fetch(PROFILE_API, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "Authorization": authToken
            },
            body: JSON.stringify(requestBody)
        });

        const data = await response.json();
        if (!data.uploadUrl) {
            showMessage("Failed to get upload URL", true);
            return;
        }

        // Step 2: Upload image directly to S3
        const uploadRes = await fetch(data.uploadUrl, {
            method: "PUT",
            headers: {
                "Content-Type": "image/jpeg"
            },
            body: file
        });

        if (!uploadRes.ok) {
            showMessage("Upload to S3 failed", true);
            return;
        }

        showMessage("Profile Picture uploaded successfully!", false);
        await fetchProfilePicture(); 
    } catch (error) {
        console.error("Hybrid Upload Error:", error);
        showMessage("Upload failed", true);
    }
}

// Logout Handler
document.getElementById("logoutBtn").addEventListener("click", () => {
    // ✅ DYNAMICALLY INJECTED BY CODEBUILD PIPELINE VIA TERRAFORM
    const logoutUri = "__LOGOUT_URI__";
    window.location.href = `https://${COGNITO_DOMAIN}/logout?client_id=${clientId}&logout_uri=${encodeURIComponent(logoutUri)}`;
});

// Event listener for file input change event (choosing file)
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

// Event listener for Upload Button click
uploadBtn.addEventListener("click", async () => {
    if (!selectedFile) {
        showMessage("Please choose a file first", true);
        return;
    }
    await handleFileUpload(selectedFile);
});

// Function to fetch the user's profile picture
async function fetchProfilePicture() {
    const profilePic = document.getElementById("profilePic");
    // Get a reference to your new navbar image element too
    const navProfilePic = document.getElementById("navProfilePic"); 
    const defaultImage = "images/default-profile.png";
    
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) {
            profilePic.src = defaultImage;
            if (navProfilePic) navProfilePic.src = defaultImage; // Set default
            return;
        }
        
        const payload = JSON.parse(atob(authToken.split('.')[1]));
        const username = payload['cognito:username'];
        if (!username) {
            profilePic.src = defaultImage;
            if (navProfilePic) navProfilePic.src = defaultImage; // Set default
            return;
        }

        const urlWithParams = `${PROFILE_API}?username=${encodeURIComponent(username)}`;
        
        const response = await fetch(urlWithParams, {
            method: "GET",
            headers: {
                "Authorization": authToken
            }
        });

        if (response.status === 404) {
            profilePic.src = defaultImage;
            if (navProfilePic) navProfilePic.src = defaultImage; // Set default
            return;
        }

        if (!response.ok) {
            console.error("Unexpected error:", response.status);
            profilePic.src = defaultImage;
            if (navProfilePic) navProfilePic.src = defaultImage; // Set default
            return;
        }

        const data = await response.json();
        const finalUrl = data.url || defaultImage;
        
        // Update the main big profile card image
        profilePic.src = finalUrl; 
        
        // ✅ Update the small circular navbar dropdown image smoothly!
        if (navProfilePic) {
            navProfilePic.src = finalUrl;
        }
        
    } catch (error) {
        console.error("Fetch error:", error);
        profilePic.src = defaultImage;
        if (navProfilePic) navProfilePic.src = defaultImage; // Set default fallback
    }
}

// Initialize the profile page
document.addEventListener('DOMContentLoaded', async () => {
    try {
        console.log("Initializing profile page...");

        const authToken = localStorage.getItem('authToken');
        if (!authToken) {
            showMessage('Please login first', true);
            console.warn("No authenticated user found. Redirecting...");
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