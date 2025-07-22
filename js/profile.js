// AWS Configuration
const region = "ap-southeast-1";
const identityPoolId = "ap-southeast-1:3b4324f5-c724-46c5-aa69-c74719e681c7";
const userPoolId = "ap-southeast-1_t4OcTbD3r";
const clientId = "5k18fu9gla3nf1ajmgb0nu0822";

// Cognito Setup
let userPool;
if (typeof AmazonCognitoIdentity !== 'undefined') {
    userPool = new AmazonCognitoIdentity.CognitoUserPool({
        UserPoolId: userPoolId,
        ClientId: clientId
    });
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

// Utility Functions
function showMessage(message, isError = false) {
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
}

function fileToBase64(file) {
    return new Promise((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result.split(',')[1]);
        reader.onerror = error => reject(error);
        reader.readAsDataURL(file);
    });
}

function displayImagePreview(file) {
    const reader = new FileReader();
    reader.onload = () => profilePic.src = reader.result;
    reader.readAsDataURL(file);
}

async function resizeImage(file, maxWidth = 800, quality = 0.7) {
    return new Promise((resolve) => {
        const reader = new FileReader();
        reader.onload = (e) => {
            const img = new Image();
            img.onload = () => {
                const canvas = document.createElement('canvas');
                const scale = Math.min(maxWidth / img.width, 1);
                canvas.width = img.width * scale;
                canvas.height = img.height * scale;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                canvas.toBlob((blob) => resolve(blob), 'image/jpeg', quality);
            };
            img.src = e.target.result;
        };
        reader.readAsDataURL(file);
    });
}

// Upload Handlers
async function handleModernUpload(file) {
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) throw new Error("Not authenticated");
        
        // Resize image first
        const processedFile = await resizeImage(file);
        
        // Get presigned URL
        const response = await fetch(
            "https://y41x5c3mi6.execute-api.ap-southeast-1.amazonaws.com/prod/profileimagetos3",
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": authToken
                },
                body: JSON.stringify({
                    fileType: "image/jpeg"
                })
            }
        );
        
        const { uploadUrl } = await response.json();
        
        // Upload directly to S3
        await fetch(uploadUrl, {
            method: "PUT",
            body: processedFile,
            headers: { "Content-Type": "image/jpeg" }
        });
        
        // Create object URL for immediate display
        profilePic.src = URL.createObjectURL(processedFile);
        showMessage("Upload successful!", false);
        
    } catch (error) {
        console.error("Modern upload failed:", error);
        throw error; // Fallback to legacy
    }
}

async function handleLegacyUpload(file) {
    try {
        const authToken = localStorage.getItem('authToken');
        const base64Image = await fileToBase64(file);
        const payload = JSON.parse(atob(authToken.split('.')[1]));
        
        const response = await fetch(
            "https://y41x5c3mi6.execute-api.ap-southeast-1.amazonaws.com/prod/profileimagetos3",
            {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Authorization": authToken
                },
                body: JSON.stringify({
                    username: payload['cognito:username'],
                    image: base64Image
                })
            }
        );
        
        const data = await response.json();
        if (data.url) {
            profilePic.src = data.url;
            showMessage("Upload successful (legacy mode)!", false);
        }
    } catch (error) {
        console.error("Legacy upload failed:", error);
        throw error;
    }
}

async function handleFileUpload(file) {
    showMessage("Uploading...", false);
    
    try {
        // Try modern upload first
        await handleModernUpload(file);
    } catch (error) {
        console.log("Falling back to legacy upload");
        await handleLegacyUpload(file);
    }
}

// Event Listeners
fileInput.addEventListener("change", async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    if (!file.type.startsWith('image/')) {
        showMessage("Only images allowed", true);
        return;
    }
    if (file.size > 10 * 1024 * 1024) {
        showMessage("Image must be <10MB", true);
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

// Profile Management
async function fetchUserProfile() {
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) throw new Error('No authentication data');

        const payload = JSON.parse(atob(authToken.split('.')[1]));
        const userData = {
            username: payload['cognito:username'],
            email: payload.email
        };
        
        document.getElementById("username").textContent = userData.username;
        document.getElementById("email").textContent = userData.email;
    } catch (error) {
        console.error('Profile Error:', error);
        showMessage("Redirecting to login...", true);
        setTimeout(() => window.location.href = "index.html", 2000);
    }
}

async function fetchProfilePicture() {
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) return;
        
        const payload = JSON.parse(atob(authToken.split('.')[1]));
        const username = payload['cognito:username'];
        
        const response = await fetch(
            `https://y41x5c3mi6.execute-api.ap-southeast-1.amazonaws.com/prod/profileimagetos3?username=${encodeURIComponent(username)}`,
            {
                headers: { "Authorization": authToken }
            }
        );
        
        const data = await response.json();
        profilePic.src = data.url || "default-profile.png";
    } catch (error) {
        console.error("Fetch error:", error);
        profilePic.src = "default-profile.png";
    }
}

// Logout Handler
document.getElementById("logoutBtn").addEventListener("click", () => {
    const logoutUri = "https://baylenwebsite.xyz";
    const cognitoDomain = "https://zeref-todolist-auth.auth.ap-southeast-1.amazoncognito.com";
    window.location.href = `${cognitoDomain}/logout?client_id=${clientId}&logout_uri=${encodeURIComponent(logoutUri)}`;
});

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) {
            showMessage('Please login first', true);
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