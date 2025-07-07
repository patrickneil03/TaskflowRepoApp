const apiUrl = 'https://y41x5c3mi6.execute-api.ap-southeast-1.amazonaws.com/prod/taskhandler';

// Global variable to store the selected deadline
let selectedDeadline = null;

// ==================================================
// Config & Constants
// ==================================================
const CLIENT_ID       = "5k18fu9gla3nf1ajmgb0nu0822";
const COGNITO_DOMAIN  = "zeref-todolist-auth.auth.ap-southeast-1.amazoncognito.com";
const REDIRECT_URI    = "http://localhost:8000/dashboard.html";
const LOGIN_PAGE      = "index.html";
const TOKEN_EXCHANGE_URL =
  "https://y41x5c3mi6.execute-api.ap-southeast-1.amazonaws.com/prod/token";

// ==================================================
// 1) Federated login helper
// ==================================================
function federatedLogin(provider /* "Google" or "Facebook" */) {
  const url = new URL(`https://${COGNITO_DOMAIN}/oauth2/authorize`);
  url.searchParams.set("identity_provider", provider);
  url.searchParams.set("client_id", CLIENT_ID);
  url.searchParams.set("redirect_uri", REDIRECT_URI);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "openid email profile"); // no offline_access
  url.searchParams.set("prompt", "login");               // force fresh auth
  window.location.href = url.toString();
}

// ==================================================
// 2) Handle OAuth callback & persist IdP
// ==================================================
async function handleOAuthCallback() {
  const params   = new URLSearchParams(window.location.search);
  const code     = params.get("code");
  const provider = params.get("identity_provider") || "Cognito";
  if (!code) return;

  console.log("OAuth code:", code, "via", provider);
  localStorage.setItem("idpProvider", provider);

  try {
    const resp = await fetch(TOKEN_EXCHANGE_URL, {
      method:  "POST",
      headers: { "Content-Type": "application/json" },
      body:    JSON.stringify({ code }),
    });
    if (!resp.ok) throw new Error("Token exchange failed");

    const { id_token, refresh_token = "" } = await resp.json();
    localStorage.setItem("authToken", id_token);
    localStorage.setItem("refreshToken", refresh_token);

    window.history.replaceState({}, "", REDIRECT_URI);
    fetchTodos();
  } catch (err) {
    console.error("OAuth error:", err);
    alert("Login failed; returning to sign-in page…");
    setTimeout(() => (window.location.href = LOGIN_PAGE), 3000);
  }
}

// ==================================================
// 3) Refresh ID token (Option B style)
// ==================================================
async function refreshIdToken() {
  const provider     = localStorage.getItem("idpProvider") || "Cognito";
  const refreshToken = localStorage.getItem("refreshToken");

  // Facebook never gets a refresh token via Cognito
  if (provider === "Facebook" || !refreshToken) {
    console.warn("No refresh token for Facebook – re-authenticating");
    federatedLogin("Facebook");
    return null;  // bail out, redirect in progress
  }

  // Perform standard refresh_token grant for Cognito/native & Google
  const form = new URLSearchParams({
    grant_type:    "refresh_token",
    client_id:     CLIENT_ID,
    refresh_token: refreshToken,
  });

  const resp = await fetch(
    `https://${COGNITO_DOMAIN}/oauth2/token`,
    {
      method:  "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body:    form.toString(),
    }
  );
  if (!resp.ok) throw new Error("Token refresh failed");

  const { id_token } = await resp.json();
  localStorage.setItem("authToken", id_token);
  return id_token;
}

// ==================================================
// 4) JWT expiry helper
// ==================================================
function isTokenExpired(token) {
  if (!token) return true;
  try {
    const { exp } = JSON.parse(atob(token.split(".")[1]));
    return exp < Math.floor(Date.now() / 1000);
  } catch {
    return true;
  }
}



// Initialize deadline functionality
document.addEventListener('DOMContentLoaded', function() {
    const deadlineToggle = document.getElementById('deadline-toggle');
    if (deadlineToggle) {
        deadlineToggle.addEventListener('click', toggleDeadlinePicker);
    }
});

function toggleDeadlinePicker() {
    const pickerContainer = document.getElementById('deadline-picker-container');
    if (pickerContainer.style.display === 'block') {
        pickerContainer.style.display = 'none';
    } else {
        // Position the picker near the button
        const button = document.getElementById('deadline-toggle');
        const rect = button.getBoundingClientRect();
        pickerContainer.style.top = `${rect.bottom + window.scrollY + 5}px`;
        pickerContainer.style.left = `${rect.left + window.scrollX}px`;
        pickerContainer.style.display = 'block';
        
        // Set minimum date to today
        const now = new Date();
        const localDateTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        document.getElementById('deadline-input').min = localDateTime;
    }
}

function confirmDeadline() {
    const deadlineInput = document.getElementById('deadline-input');
    selectedDeadline = deadlineInput.value;
    document.getElementById('deadline-picker-container').style.display = 'none';
    
    // Visual feedback that deadline is set
    const deadlineToggle = document.getElementById('deadline-toggle');
    deadlineToggle.innerHTML = `<i class="far fa-calendar-check"></i> Deadline Set`;
    deadlineToggle.style.backgroundColor = '#28a745';
    
    // Reset after 2 seconds
    setTimeout(() => {
        deadlineToggle.innerHTML = `<i class="far fa-calendar-alt"></i> Set Deadline`;
        deadlineToggle.style.backgroundColor = '';
    }, 2000);
}

function cancelDeadline() {
    selectedDeadline = null;
    document.getElementById('deadline-input').value = '';
    document.getElementById('deadline-picker-container').style.display = 'none';
}

// Helper functions for deadline display
function formatDeadline(isoString) {
    if (!isoString) return '';
    const date = new Date(isoString);
    return date.toLocaleString();
}

function getDeadlineClass(deadline) {
    if (!deadline) return '';
    const now = new Date();
    const dueDate = new Date(deadline);
    const hoursUntilDeadline = (dueDate - now) / (1000 * 60 * 60);
    
    if (hoursUntilDeadline < 0) return 'deadline-urgent'; // Past due
    if (hoursUntilDeadline < 24) return 'deadline-warning'; // Due within 24 hours
    return '';
}





function showInlineDeadlineEditor(taskId) {
  const editor = document.getElementById(`deadline-editor-${taskId}`);
  if (editor) editor.style.display = 'flex';
}

function hideInlineDeadlineEditor(taskId) {
  const editor = document.getElementById(`deadline-editor-${taskId}`);
  if (editor) editor.style.display = 'none';
}

function confirmUpdatedDeadline(taskId) {
  const input = document.getElementById(`deadline-dt-${taskId}`);
  if (input && input.value) {
    updateDeadline(taskId, input.value); // Implement this to update DynamoDB
  }
  hideInlineDeadlineEditor(taskId);
}

function cancelUpdatedDeadline(taskId) {
  hideInlineDeadlineEditor(taskId);
}

async function fetchTodos() {
  const idToken = localStorage.getItem('authToken');
  if (!idToken) return displayErrorMessage('ID token is missing');
  try {
    const response = await fetch(apiUrl, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${idToken}`,
        'Content-Type': 'application/json'
      }
    });

    const todos = await response.json();
    const todoList = document.getElementById('todo-list');
    todoList.innerHTML = '';

    todos.forEach(todo => {
      const li = document.createElement('li');
      li.className = 'todo-item';

      li.innerHTML = `
        <div class="todo-content">
          <div class="todo-text-block">
            <input type="text" value="${todo.taskText}" id="todo-text-${todo.taskId}">
            <div class="task-meta">
              <span class="task-created">${todo.createdAt ? 'Created: ' + todo.createdAt : ''}</span>
              <div class="deadline-row">
                ${todo.deadline ? `
                  <span class="deadline-label ${getDeadlineClass(todo.deadline)}">
                    <i class="far fa-clock"></i> Due: ${formatDeadline(todo.deadline)}
                  </span>` : ''}
                <button class="btn-icon edit-deadline-btn" id="edit-btn-${todo.taskId}">
                  <i class="fas fa-edit"></i>
                </button>
              </div>
              <div class="deadline-editor-container" id="deadline-editor-${todo.taskId}" style="display: none;">
                <input
                  type="datetime-local"
                  class="deadline-editor-input"
                  id="deadline-dt-${todo.taskId}"
                  value="${todo.deadline || ''}"
                />
                <button class="deadline-btn deadline-btn-confirm" id="confirm-btn-${todo.taskId}">OK</button>
                <button class="deadline-btn deadline-btn-cancel" id="cancel-btn-${todo.taskId}">Cancel</button>
              </div>
            </div>
          </div>
          <div class="todo-actions">
            <button class="btn btn-small btn-update" onclick="updateTodo('${todo.taskId}')">
              <i class="fas fa-edit"></i>
            </button>
            <button class="btn btn-small btn-delete" onclick="deleteTodo('${todo.taskId}')">
              <i class="fas fa-trash-alt"></i>
            </button>
          </div>
        </div>
		
		<div
    class="todo-status"
    id="todo-status-${todo.taskId}"
    style="min-height:1em; margin-top:4px; color:green; font-size:0.9rem;"
  ></div>
      `;

      todoList.appendChild(li);

      li.querySelector(`#edit-btn-${CSS.escape(todo.taskId)}`)?.addEventListener('click', () => {
        showInlineDeadlineEditor(todo.taskId);
      });
      li.querySelector(`#confirm-btn-${CSS.escape(todo.taskId)}`)?.addEventListener('click', () => {
        confirmUpdatedDeadline(todo.taskId);
      });
      li.querySelector(`#cancel-btn-${CSS.escape(todo.taskId)}`)?.addEventListener('click', () => {
        cancelUpdatedDeadline(todo.taskId);
      });
    });
  } catch (error) {
    console.error('Error fetching todos:', error);
    displayErrorMessage(`Error: ${error.message}`);
  }
}



function triggerDatePicker(taskId) {
  const input = document.getElementById(`deadline-editor-${taskId}`);
  if (input) input.showPicker?.() || input.focus(); // `showPicker()` for modern browsers, fallback to focus
}


// Function to create a new todo
async function createTodo() {
    idToken = localStorage.getItem('authToken');
    console.log('Fetched ID token:', idToken);

    if (!idToken) {
        displayErrorMessage('ID token is missing. Please log in again.');
        return;
    }

    if (isTokenExpired(idToken)) {
        await refreshIdToken();
        idToken = localStorage.getItem('authToken');
        console.log('Fetched new ID token after refresh:', idToken);
    }

    const text = document.getElementById('new-todo').value;
    if (!text) {
        displayErrorMessage('Task text cannot be empty');
        return;
    }

    // Prepare the todo data with optional deadline
    const todoData = {
        taskText: text
    };

    // Add deadline if it was set
    if (selectedDeadline) {
        todoData.deadline = selectedDeadline;
        console.log('Creating todo with deadline:', selectedDeadline);
    }

    try {
        console.log('Sending request to create todo:', todoData);
        const response = await fetch(apiUrl, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}`
            },
            body: JSON.stringify(todoData)
        });

        console.log('Response status:', response.status);
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Failed to create todo: ${errorData.message || response.statusText}`);
        }

        // Reset form and deadline selection
        document.getElementById('new-todo').value = '';
        selectedDeadline = null;
        
        // Reset deadline button visual state if it exists
        const deadlineToggle = document.getElementById('deadline-toggle');
        if (deadlineToggle) {
            deadlineToggle.innerHTML = `<i class="far fa-calendar-alt"></i> Set Deadline`;
            deadlineToggle.style.backgroundColor = '';
        }
        
        fetchTodos();
    } catch (error) {
        console.error('Error creating todo:', error);
        displayErrorMessage(`Error creating todo: ${error.message || 'Unknown error'}`);
    }
}



//function for update deadline for tasks
async function updateDeadline(taskId, newDeadline) {
  try {
    const idToken = localStorage.getItem('authToken');
    if (!idToken) throw new Error('Missing auth token');

    const response = await fetch(`${apiUrl}/${taskId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}`
      },
     body: JSON.stringify({
  deadline: newDeadline,
 
 // reset notification flag
      })
    });

    if (!response.ok) {
      throw new Error(`Failed to update deadline: ${response.statusText}`);
    }

    // Optional: Refresh the task list to reflect changes
    await fetchTodos();
  } catch (error) {
    console.error('Error updating deadline:', error);
    displayErrorMessage(`Could not update deadline: ${error.message}`);
  }
}

// Function to update an existing todo
async function updateTodo(id) {
    idToken = localStorage.getItem('authToken');
    console.log('Fetched ID token:', idToken);
    if (isTokenExpired(idToken)) {
        await refreshIdToken();
        idToken = localStorage.getItem('authToken');
        console.log('Fetched new ID token after refresh:', idToken);
    }

    const text = document.getElementById(`todo-text-${id}`).value;
    
    // Check if we're in deadline selection mode for this update
    const currentDeadline = selectedDeadline;
    const resetDeadlineUI = () => {
        selectedDeadline = null;
        const deadlineToggle = document.getElementById('deadline-toggle');
        if (deadlineToggle) {
            deadlineToggle.innerHTML = `<i class="far fa-calendar-alt"></i> Set Deadline`;
            deadlineToggle.style.backgroundColor = '';
        }
    };

    try {
        // Prepare update data with optional deadline
        const updateData = { taskText: text };
        if (currentDeadline) {
            updateData.deadline = currentDeadline;
            console.log('Updating todo with new deadline:', currentDeadline);
        }

        const response = await fetch(`${apiUrl}/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}`
            },
            body: JSON.stringify(updateData)
        });
        
        console.log('Response status:', response.status);
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Failed to update todo: ${errorData.message || response.statusText}`);
        }
        
        // Reset deadline UI if we used it
        if (currentDeadline) {
            resetDeadlineUI();
        }
		
		 displaySuccessMessage('Task updated successfully!', id);
        
        setTimeout(() => {
		fetchTodos();
		}, 3000);
    } catch (error) {
        console.error('Error updating todo:', error);
        displayErrorMessage(`Error updating todo: ${error.message || 'Unknown error'}`);
        
        // Reset deadline UI on error if we were using it
        if (currentDeadline) {
            resetDeadlineUI();
        }
    }
}

// per‐item success
function displaySuccessMessage(msg, id) {
  const statusEl = document.getElementById(`todo-status-${id}`);
  if (!statusEl) return;
  statusEl.textContent = msg;
  statusEl.style.color = 'green';
  setTimeout(() => { statusEl.textContent = ''; }, 5000);
}

// per‐item error (assuming you have one)
function displayErrorMessage(msg, id) {
  const statusEl = document.getElementById(`todo-status-${id}`);
  if (!statusEl) return;
  statusEl.textContent = msg;
  statusEl.style.color = 'red';
  setTimeout(() => { statusEl.textContent = ''; }, 3000);
}



// Function to delete a todo
async function deleteTodo(id) {
    idToken = localStorage.getItem('authToken');
    console.log('Fetched ID token:', idToken);
    if (isTokenExpired(idToken)) {
        await refreshIdToken();
        idToken = localStorage.getItem('authToken');
        console.log('Fetched new ID token after refresh:', idToken);
    }

    try {
        const response = await fetch(`${apiUrl}/${id}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${idToken}`
            }
        });
        console.log('Response status:', response.status);
        if (!response.ok) throw new Error(`Failed to delete todo: ${response.statusText}`);
        fetchTodos();
    } catch (error) {
        console.error('Error deleting todo:', error);
        displayErrorMessage(`Error deleting todo: ${error.message || 'Unknown error'}`);
    }
}

// Function to handle logout
function logout() {
    // 1. Clear ALL client-side storage
    localStorage.clear();
    sessionStorage.clear();
    
    // 2. Delete all Cognito-related cookies
    document.cookie.split(';').forEach(cookie => {
        const [name] = cookie.trim().split('=');
        if (name.startsWith('CognitoIdentityServiceProvider') || 
            name.startsWith('amplify-auth') ||
            name.startsWith('XSRF-TOKEN')) {
            document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=${window.location.hostname};`;
        }
    });

    // 3. Force full Cognito logout with federated signout
    const clientId = "5k18fu9gla3nf1ajmgb0nu0822";
    const logoutUri = "http://localhost:8000";
    const cognitoDomain = "https://zeref-todolist-auth.auth.ap-southeast-1.amazoncognito.com";
    
    // 4. Redirect with parameters that ensure complete logout
    window.location.href = `${cognitoDomain}/logout?` +
    `client_id=${clientId}&` +
    `logout_uri=${encodeURIComponent(logoutUri)}`;
}

window.onload = async () => {
  const path   = window.location.pathname;
  const params = new URLSearchParams(window.location.search);

  // 1) Finish any OAuth code exchange
  if (params.get("code")) {
    await handleOAuthCallback();
    return;
  }

  // 2) If we’re on the dashboard, try to get a valid token…
  if (path.includes("dashboard.html")) {
    try {
      // grab whatever’s in storage
      let token = localStorage.getItem("authToken") || "";

      // if it’s expired (or missing), try to refresh
      if (!token || isTokenExpired(token)) {
        token = await refreshIdToken();
      }

      // 3) **Only** if we actually have a token do we proceed
      if (token) {
        fetchTodos();
      }
      // if token is null (FB path), federatedLogin() has already redirected us  
      // so we simply `return` here and do nothing
      return;
    }
    catch (err) {
      console.error("Init error:", err);
      // for non-FB errors, send back to sign-in
      const idp = localStorage.getItem("idpProvider") || "Cognito";
      if (idp !== "Facebook") {
        window.location.href = "index.html";
      }
    }
  }
};


// Utility function to display error messages
function displayErrorMessage(message) {
    const errorElement = document.getElementById('error-message');
    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
        setTimeout(() => {
            errorElement.style.display = 'none';
        }, 5000);
    } else {
        alert(message);
    }
}