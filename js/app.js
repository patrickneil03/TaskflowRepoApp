const apiUrl = 'https://api.baylenwebsite.xyz/taskhandler';

// Global variable to store the selected deadline
let selectedDeadline = null;

// ==================================================
// Config & Constants
// ==================================================
const CLIENT_ID          = "__COGNITO_CLIENT_ID__";
const COGNITO_DOMAIN     = "__CUSTOM_COGNITO_DOMAIN__";
const REDIRECT_URI       = "https://baylenwebsite.xyz/dashboard.html";
const LOGIN_PAGE         = "index.html";
const TOKEN_EXCHANGE_URL = "https://api.baylenwebsite.xyz/token";

// ==================================================
// Native Event Handling Interceptors (Consolidated navbar logic)
// ==================================================
document.addEventListener('DOMContentLoaded', function() {
    // 1. Navigation Panel Dropdown Handler
    const dropdownToggle = document.getElementById('dropdown-toggle');
    const dropdownMenu = document.getElementById('dropdown-menu');
    
    if (dropdownToggle && dropdownMenu) {
        dropdownToggle.addEventListener('click', function(e) {
            e.stopPropagation();
            dropdownMenu.classList.toggle('show');
        });
        
        document.addEventListener('click', function() {
            dropdownMenu.classList.remove('show');
        });
        
        dropdownMenu.addEventListener('click', function(e) {
            e.stopPropagation();
        });
    }

    // 2. Deadline Toggle Interceptor
    const deadlineToggle = document.getElementById('deadline-toggle');
    if (deadlineToggle) {
        deadlineToggle.addEventListener('click', toggleDeadlinePicker);
    }
});

// ==================================================
// Auth & Tokens
// ==================================================
function federatedLogin(provider) {
  const url = new URL(`https://${COGNITO_DOMAIN}/oauth2/authorize`);
  url.searchParams.set("identity_provider", provider);
  url.searchParams.set("client_id", CLIENT_ID);
  url.searchParams.set("redirect_uri", REDIRECT_URI);
  url.searchParams.set("response_type", "code");
  url.searchParams.set("scope", "openid email profile");
  url.searchParams.set("prompt", "login");
  window.location.href = url.toString();
}

async function handleOAuthCallback() {
  const params   = new URLSearchParams(window.location.search);
  const code     = params.get("code");
  const provider = params.get("identity_provider") || "Cognito";
  if (!code) return;

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

async function refreshIdToken() {
  const provider     = localStorage.getItem("idpProvider") || "Cognito";
  const refreshToken = localStorage.getItem("refreshToken");

  if (provider === "Facebook" || !refreshToken) {
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

function isTokenExpired(token) {
  if (!token) return true;
  try {
    const { exp } = JSON.parse(atob(token.split(".")[1]));
    return exp < Math.floor(Date.now() / 1000);
  } catch {
    return true;
  }
}

// ==================================================
// Deadline Logic
// ==================================================
function toggleDeadlinePicker() {
    const pickerContainer = document.getElementById('deadline-picker-container');
    if (pickerContainer.style.display === 'block') {
        pickerContainer.style.display = 'none';
    } else {
        pickerContainer.style.display = 'block';
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
    
    setTimeout(() => {
        deadlineToggle.innerHTML = `<i class="far fa-calendar-alt"></i> Set Deadline`;
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
    
    if (dueDate < now) {
        return 'deadline-urgent'; // Red color style override
    }
    
    const hoursUntilDeadline = (dueDate - now) / (1000 * 60 * 60);
    if (hoursUntilDeadline < 24) {
        return 'deadline-warning'; // Yellow color
    }
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
    updateDeadline(taskId, input.value);
  }
  hideInlineDeadlineEditor(taskId);
}

function cancelUpdatedDeadline(taskId) {
  hideInlineDeadlineEditor(taskId);
}

// ==================================================
// Task CRUD Communications
// ==================================================
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
        <div class="todo-content" style="width: 100%;">
          <div class="todo-text-block">
            <span class="todo-text" style="font-size: 1.15rem; font-weight: 600; color: var(--text-color);">
              ${todo.taskText}
            </span>
            
            <div class="task-meta" style="margin-top: 4px;">
              <span class="task-created" style="font-size: 0.75rem; color: var(--text-muted);">
                ${todo.createdAt ? 'Created: ' + todo.createdAt : ''}
              </span>
              
              <div class="deadline-row" style="margin-top: 4px;">
                ${todo.deadline ? `
                  <span class="deadline-label ${getDeadlineClass(todo.deadline)}">
                    <i class="far fa-clock"></i> Due: ${formatDeadline(todo.deadline)}
                  </span>` : ''}
                <button class="btn-icon edit-deadline-btn" id="edit-btn-${todo.taskId}">
                  <i class="fas fa-edit"></i>
                </button>
              </div>
              
              <div class="deadline-editor-container" id="deadline-editor-${todo.taskId}" style="display: none; margin-top: 8px;">
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
            <button class="btn btn-small btn-delete" onclick="deleteTodo('${todo.taskId}')">
              <i class="fas fa-trash-alt"></i>
            </button>
          </div>
        </div>
        
        <div class="todo-status" id="todo-status-${todo.taskId}" style="min-height:1em; margin-top:4px; color:green; font-size:0.9rem;"></div>
      `;

      todoList.appendChild(li);

      // Explicit target listener mapping logic
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

async function createTodo() {
    let idToken = localStorage.getItem('authToken');
    if (!idToken) {
        displayErrorMessage('ID token is missing. Please log in again.');
        return;
    }

    if (isTokenExpired(idToken)) {
        await refreshIdToken();
        idToken = localStorage.getItem('authToken');
    }

    const text = document.getElementById('new-todo').value;
    if (!text) {
        displayErrorMessage('Task text cannot be empty');
        return;
    }

    const todoData = { taskText: text };

    if (selectedDeadline) {
        todoData.deadline = selectedDeadline;
    }

    try {
        const response = await fetch(apiUrl, {
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
        fetchTodos();
    } catch (error) {
        console.error('Error creating todo:', error);
        displayErrorMessage(`Error creating todo: ${error.message || 'Unknown error'}`);
    }
}

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
     body: JSON.stringify({ deadline: newDeadline })
    });

    if (!response.ok) {
      throw new Error(`Failed to update deadline: ${response.statusText}`);
    }

    await fetchTodos();
  } catch (error) {
    console.error('Error updating deadline:', error);
    displayErrorMessage(`Could not update deadline: ${error.message}`);
  }
}

function displayErrorMessage(msg, id) {
  const statusEl = document.getElementById(`todo-status-${id}`);
  if (!statusEl) {
    const errorElement = document.getElementById('error-message');
    if (errorElement) {
        errorElement.textContent = msg;
        errorElement.style.display = 'block';
        setTimeout(() => { errorElement.style.display = 'none'; }, 5000);
    }
    return;
  }
  statusEl.textContent = msg;
  statusEl.style.color = 'red';
  setTimeout(() => { statusEl.textContent = ''; }, 3000);
}

async function deleteTodo(id) {
    let idToken = localStorage.getItem('authToken');
    if (isTokenExpired(idToken)) {
        await refreshIdToken();
        idToken = localStorage.getItem('authToken');
    }

    try {
        const response = await fetch(`${apiUrl}/${id}`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${idToken}` }
        });
        if (!response.ok) throw new Error(`Failed to delete todo: ${response.statusText}`);
        fetchTodos();
    } catch (error) {
        console.error('Error deleting todo:', error);
        displayErrorMessage(`Error deleting todo: ${error.message || 'Unknown error'}`);
    }
}

function logout() {
    localStorage.clear();
    sessionStorage.clear();
    const logoutUri = "https://baylenwebsite.xyz";
    window.location.href = `https://${COGNITO_DOMAIN}/logout?client_id=${CLIENT_ID}&logout_uri=${encodeURIComponent(logoutUri)}`;
}

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
      }
    } catch (err) {
      console.error("Init error:", err);
      window.location.href = "index.html";
    }
  }
};