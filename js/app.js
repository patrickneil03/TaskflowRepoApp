// ✅ DYNAMICALLY INJECTED BY CODEBUILD PIPELINE VIA TERRAFORM
const TASKHANDLER_API    = "__API_URL__";
const TOKEN_EXCHANGE_URL = "__TOKEN_EXCHANGE_URL__";
const REDIRECT_URI       = "__REDIRECT_URI__";
const CLIENT_ID          = "__COGNITO_CLIENT_ID__";
const COGNITO_DOMAIN     = "__CUSTOM_COGNITO_DOMAIN__";
const LOGIN_PAGE         = "index.html";

// Global variable to store the selected deadline
let selectedDeadline = null;

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

  if (provider === "Facebook" || !refreshToken) {
    console.warn("No refresh token for Facebook – re-authenticating");
    federatedLogin("Facebook");
    return null;
  }

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
    
    if (pickerContainer.style.display === 'block' || pickerContainer.style.display === 'flex') {
        pickerContainer.style.display = 'none';
    } else {
        // ✅ FIXED: Let CSS handle placement layout directly
        pickerContainer.style.display = 'flex'; 
        pickerContainer.style.alignItems = 'center';
        
        // Keep your fallback time restrictions
        const now = new Date();
        const localDateTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        document.getElementById('deadline-input').min = localDateTime;
    }
}

function confirmDeadline() {
    const deadlineInput = document.getElementById('deadline-input');
    selectedDeadline = deadlineInput.value;
    document.getElementById('deadline-picker-container').style.display = 'none';
    
    const deadlineToggle = document.getElementById('deadline-toggle');
    deadlineToggle.innerHTML = `<i class="far fa-calendar-check"></i> Deadline Set`;
    deadlineToggle.style.backgroundColor = '#28a745';
    
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
    
    if (hoursUntilDeadline < 0) return 'deadline-urgent';
    if (hoursUntilDeadline < 24) return 'deadline-warning';
    return '';
}

function showInlineDeadlineEditor(taskId) {
  const editor = document.getElementById(`deadline-editor-${taskId}`);
  if (editor) editor.style.display = 'flex';
}

// Target elements inline per task error element
function displayInlineErrorMessage(msg, id) {
  const statusEl = document.getElementById(`todo-status-${id}`);
  if (!statusEl) return;
  statusEl.textContent = msg;
  statusEl.style.color = 'red';
  setTimeout(() => { statusEl.textContent = ''; }, 3000);
}

function hideInlineDeadlineEditor(taskId) {
  const editor = document.getElementById(`deadline-editor-${taskId}`);
  if (editor) editor.style.display = 'none';
}

function confirmUpdatedDeadline(taskId) {
  const input = document.getElementById(`deadline-dt-${taskId}`);
  if (input && input.value) {
    updateDeadline(taskId, input.value);
  }
  hideInlineDeadlineEditor(taskId);
}

function cancelUpdatedDeadline(taskId) {
  hideInlineDeadlineEditor(taskId);
}

async function fetchTodos() {
  const idToken = localStorage.getItem('authToken');
  if (!idToken) return displayGlobalErrorMessage('ID token is missing');
  try {
    // ✅ Updated to use TASKHANDLER_API
    const response = await fetch(TASKHANDLER_API, {
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
    displayGlobalErrorMessage(`Error: ${error.message}`);
  }
}

function triggerDatePicker(taskId) {
  const input = document.getElementById(`deadline-editor-${taskId}`);
  if (input) input.showPicker?.() || input.focus();
}

// Function to create a new todo
async function createTodo() {
    let idToken = localStorage.getItem('authToken');
    if (!idToken) {
        displayGlobalErrorMessage('ID token is missing. Please log in again.');
        return;
    }

    if (isTokenExpired(idToken)) {
        await refreshIdToken();
        idToken = localStorage.getItem('authToken');
    }

    const text = document.getElementById('new-todo').value;
    if (!text) {
        displayGlobalErrorMessage('Task text cannot be empty');
        return;
    }

    const todoData = { taskText: text };
    if (selectedDeadline) {
        todoData.deadline = selectedDeadline;
    }

    try {
        // ✅ Updated to use TASKHANDLER_API
        const response = await fetch(TASKHANDLER_API, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}`
            },
            body: JSON.stringify(todoData)
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Failed to create todo: ${errorData.message || response.statusText}`);
        }

        document.getElementById('new-todo').value = '';
        selectedDeadline = null;
        
        const deadlineToggle = document.getElementById('deadline-toggle');
        if (deadlineToggle) {
            deadlineToggle.innerHTML = `<i class="far fa-calendar-alt"></i> Set Deadline`;
            deadlineToggle.style.backgroundColor = '';
        }
        
        fetchTodos();
    } catch (error) {
        console.error('Error creating todo:', error);
        displayGlobalErrorMessage(`Error creating todo: ${error.message || 'Unknown error'}`);
    }
}

// Function for update deadline for tasks
async function updateDeadline(taskId, newDeadline) {
  try {
    const idToken = localStorage.getItem('authToken');
    if (!idToken) throw new Error('Missing auth token');

    // ✅ Updated to use TASKHANDLER_API
    const response = await fetch(`${TASKHANDLER_API}/${taskId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}`
      },
     body: JSON.stringify({
       deadline: newDeadline
      })
    });

    if (!response.ok) {
      throw new Error(`Failed to update deadline: ${response.statusText}`);
    }

    await fetchTodos();
  } catch (error) {
    console.error('Error updating deadline:', error);
    displayGlobalErrorMessage(`Could not update deadline: ${error.message}`);
  }
}

// Function to update an existing todo
async function updateTodo(id) {
    let idToken = localStorage.getItem('authToken');
    if (isTokenExpired(idToken)) {
        await refreshIdToken();
        idToken = localStorage.getItem('authToken');
    }

    const text = document.getElementById(`todo-text-${id}`).value;
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
        const updateData = { taskText: text };
        if (currentDeadline) {
            updateData.deadline = currentDeadline;
        }

        // ✅ Updated to use TASKHANDLER_API
        const response = await fetch(`${TASKHANDLER_API}/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}`
            },
            body: JSON.stringify(updateData)
        });
        
        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(`Failed to update todo: ${errorData.message || response.statusText}`);
        }
        
        if (currentDeadline) {
            resetDeadlineUI();
        }
		
        displaySuccessMessage('Task updated successfully!', id);
        
        setTimeout(() => {
            fetchTodos();
        }, 3000);
    } catch (error) {
        console.error('Error updating todo:', error);
        displayInlineErrorMessage(`Error updating todo: ${error.message || 'Unknown error'}`, id);
        if (currentDeadline) {
            resetDeadlineUI();
        }
    }
}

function displaySuccessMessage(msg, id) {
  const statusEl = document.getElementById(`todo-status-${id}`);
  if (!statusEl) return;
  statusEl.textContent = msg;
  statusEl.style.color = 'green';
  setTimeout(() => { statusEl.textContent = ''; }, 5000);
}

// Target the main application container error element (#error-message)
function displayGlobalErrorMessage(message) {
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

// Function to delete a todo
async function deleteTodo(id) {
    let idToken = localStorage.getItem('authToken');
    if (isTokenExpired(idToken)) {
        await refreshIdToken();
        idToken = localStorage.getItem('authToken');
    }

    try {
        // ✅ Updated to use TASKHANDLER_API
        const response = await fetch(`${TASKHANDLER_API}/${id}`, {
            method: 'DELETE',
            headers: {
                'Authorization': `Bearer ${idToken}`
            }
        });
        if (!response.ok) throw new Error(`Failed to delete todo: ${response.statusText}`);
        fetchTodos();
    } catch (error) {
        console.error('Error deleting todo:', error);
        displayGlobalErrorMessage(`Error deleting todo: ${error.message || 'Unknown error'}`);
    }
}

// Function to handle logout
function logout() {
    localStorage.clear();
    sessionStorage.clear();
    
    document.cookie.split(';').forEach(cookie => {
        const [name] = cookie.trim().split('=');
        if (name.startsWith('CognitoIdentityServiceProvider') || 
            name.startsWith('amplify-auth') ||
            name.startsWith('XSRF-TOKEN')) {
            document.cookie = `${name}=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/; domain=${window.location.hostname};`;
        }
    });

    // ✅ DYNAMICALLY INJECTED BY CODEBUILD PIPELINE VIA TERRAFORM
    const logoutUri = "__LOGOUT_URI__";
    window.location.href = `https://${COGNITO_DOMAIN}/logout?client_id=${CLIENT_ID}&logout_uri=${encodeURIComponent(logoutUri)}`;
}


//this function will load the tasks and profile pics in the naviagtion pane
window.onload = async () => {
  const path   = window.location.pathname;
  const params = new URLSearchParams(window.location.search);

  if (params.get("code")) {
    await handleOAuthCallback();
    return;
  }

  if (path.includes("dashboard.html")) {
    try {
      let token = localStorage.getItem("authToken") || "";

      if (!token || isTokenExpired(token)) {
        token = await refreshIdToken();
      }

      if (token) {
        fetchTodos();
		fetchNavbarProfilePicture();
      }
      return;
    }
    catch (err) {
      console.error("Init error:", err);
      const idp = localStorage.getItem("idpProvider") || "Cognito";
      if (idp !== "Facebook") {
        window.location.href = "index.html";
      }
    }
  }
};


// ✅ Add this function to the bottom of your app.js
async function fetchNavbarProfilePicture() {
    const navPic = document.getElementById("navProfilePic");
    const defaultImage = "images/default-profile.png";
    
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) return;
        
        const payload = JSON.parse(atob(authToken.split('.')[1]));
        const username = payload['cognito:username'];
        if (!username) return;

        // Using your dynamic PROFILE_API variable from your pipeline configuration
        const response = await fetch(`__PROFILE_API_URL__?username=${encodeURIComponent(username)}`, {
            method: "GET",
            headers: { "Authorization": authToken }
        });

        if (response.ok) {
            const data = await response.json();
            if (navPic) navPic.src = data.url || defaultImage;
        }
    } catch (error) {
        console.error("Error loading navbar avatar:", error);
    }
}