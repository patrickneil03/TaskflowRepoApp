// Ensure AWS Cognito SDK is loaded first
if (typeof AmazonCognitoIdentity === 'undefined') {
    console.error("AmazonCognitoIdentity SDK is not loaded. Check your script imports.");
}

// AWS Configuration

const region = "ap-southeast-1";
const identityPoolId = "ap-southeast-1:3b4324f5-c724-46c5-aa69-c74719e681c7";
const userPoolId = "ap-southeast-1_t4OcTbD3r";
const clientId = "5k18fu9gla3nf1ajmgb0nu0822";

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
  // 1) Force it visible (override your style="display:none")
  uploadStatus.style.display = 'block';

  // 2) Clear any leftover classes/backgrounds
  uploadStatus.className = 'status-message show';
  uploadStatus.style.backgroundColor = 'transparent'; 
  uploadStatus.style.color = isError ? 'red' : 'green';

  // 3) Set the text
  uploadStatus.textContent = message;

  // 4) Fade out after 3s, then clear and hide again
  setTimeout(() => {
    uploadStatus.classList.remove('show');
    setTimeout(() => {
      uploadStatus.textContent = '';
      uploadStatus.style.display = '';  // re-apply the original inline none
    }, 300); // give CSS transition time
  }, 3000);
};


// Function to convert file to base64 string
function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => {
            // Remove the data URL part and only return base64 string
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
        profilePic.src = reader.result; // Show preview
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

        const apiUrl = "https://y41x5c3mi6.execute-api.ap-southeast-1.amazonaws.com/prod/profileimagetos3";

        showMessage("Uploading...", false);

        // Step 1: Get presigned PUT URL
        const response = await fetch(apiUrl, {
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
        await fetchProfilePicture(); // Refresh the profile picture
    } catch (error) {
        console.error("Hybrid Upload Error:", error);
        showMessage("Upload failed", true);
    }
}


// Logout Handler
document.getElementById("logoutBtn").addEventListener("click", () => {
  const clientId = "5k18fu9gla3nf1ajmgb0nu0822";
    const logoutUri = "https://baylenwebsite.xyz";
    const cognitoDomain = "https://zeref-todolist-auth.auth.ap-southeast-1.amazoncognito.com";
    window.location.href = `${cognitoDomain}/logout?client_id=${clientId}&logout_uri=${encodeURIComponent(logoutUri)}`;
});

// Event listener for file input change event (choosing file)
fileInput.addEventListener("change", async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    // Validate file type (only image files allowed)
    if (!file.type.startsWith('image/')) {
        showMessage("Only image files are allowed", true);
        return;
    }

    // Validate file size (max 5MB)
    if (file.size > 5 * 1024 * 1024) {
        showMessage("File size must be less than 5MB", true);
        return;
    }

    selectedFile = file; // Save the selected file for later upload
    displayImagePreview(file); // Show preview immediately

    // Enable the upload button now that a file is selected
    uploadBtn.disabled = false;
});

// Event listener for Upload Button click (triggers the upload to Lambda)
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
    const defaultImage = "default-profile.png";
    
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) {
            profilePic.src = defaultImage;
            return;
        }
        
        const payload = JSON.parse(atob(authToken.split('.')[1]));
        const username = payload['cognito:username'];
        if (!username) {
            profilePic.src = defaultImage;
            return;
        }

        const apiUrl = `https://y41x5c3mi6.execute-api.ap-southeast-1.amazonaws.com/prod/profileimagetos3?username=${encodeURIComponent(username)}`;
        
        const response = await fetch(apiUrl, {
		method: "GET",
		headers: {
		"Authorization": authToken
		}
		});


        if (response.status === 404) {
            // Expected missing image case
            profilePic.src = defaultImage;
            return;
        }

        if (!response.ok) {
            // Handle other errors (including 500)
            console.error("Unexpected error:", response.status);
            profilePic.src = defaultImage;
            return;
        }

        const data = await response.json();
        profilePic.src = data.url || defaultImage;
        
    } catch (error) {
        console.error("Fetch error:", error);
        profilePic.src = defaultImage;
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

        await fetchUserProfile(); // Fetch and display username & email
        await fetchProfilePicture(); // Fetch and display profile picture
    } catch (error) {
        console.error('Initialization error:', error);
        setTimeout(() => window.location.href = "index.html", 2000);
    }
});

