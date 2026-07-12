// ✅ DYNAMICALLY INJECTED BY CODEBUILD PIPELINE VIA TERRAFORM
const TASKHANDLER_API    = "__API_URL__";
const PROFILE_API        = "__PROFILE_API_URL__";
const TOKEN_EXCHANGE_URL = "__TOKEN_EXCHANGE_URL__";
const REDIRECT_URI       = "__REDIRECT_URI__";
const CLIENT_ID          = "__COGNITO_CLIENT_ID__";
const COGNITO_DOMAIN     = "__CUSTOM_COGNITO_DOMAIN__";
const LOGIN_PAGE         = "index.html";

// 🎯 GLOBAL STATE ENGINE: Keeps track of tasks locally for instantaneous UI updates
let tasksState = [];
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
  url.searchParams.set("scope", "openid email profile");
  url.searchParams.set("prompt", "login");
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
        pickerContainer.style.display = 'flex'; 
        pickerContainer.style.alignItems = 'center';
        
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

// 🎯 STATE RENDERING ENGINE: Draws UI out of local memory state arrays instantly
function renderTasksUI() {
    const todoList = document.getElementById('todo-list');
    if (!todoList) return;
    todoList.innerHTML = '';

    if (tasksState.length === 0) {
        todoList.innerHTML = '<div style="text-align:center; padding:20px; color:#666;">No tasks found! Add one above.</div>';
        return;
    }

    tasksState.forEach(todo => {
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
        
        <div class="todo-status" id="todo-status-${todo.taskId}" style="min-height:1em; margin-top:4px; color:green; font-size:0.9rem;"></div>
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
}

// Get Data from Server
async function fetchTodos() {
  const idToken = localStorage.getItem('authToken');
  if (!idToken) return displayGlobalErrorMessage('ID token is missing');
  try {
    const response = await fetch(TASKHANDLER_API, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${idToken}`, // Aligned Bearer syntax
        'Content-Type': 'application/json'
      }
    });

    const todos = await response.json();
    
    // Update global memory state and persistent browser cache
    tasksState = todos;
    localStorage.setItem("cached_todo_list", JSON.stringify(todos));
    
    // Draw UI smoothly from verified response
    renderTasksUI();
  } catch (error) {
    console.error('Error fetching todos:', error);
    displayGlobalErrorMessage(`Error: ${error.message}`);
  }
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

    // 🚀 OPTIMISTIC UI: Form temporary client model element
    const tempId = "temp-" + Date.now();
    const newTodoLocal = {
        taskId: tempId,
        taskText: text,
        createdAt: "Pending synchronization...",
        deadline: selectedDeadline
    };

    // Prepend to current screen model array instantly
    tasksState.unshift(newTodoLocal);
    renderTasksUI();

    // Clear input forms right away
    document.getElementById('new-todo').value = '';
    const savedDeadline = selectedDeadline;
    selectedDeadline = null;
    
    const deadlineToggle = document.getElementById('deadline-toggle');
    if (deadlineToggle) {
        deadlineToggle.innerHTML = `<i class="far fa-calendar-alt"></i> Set Deadline`;
        deadlineToggle.style.backgroundColor = '';
    }

    try {
        const todoData = { taskText: text };
        if (savedDeadline) todoData.deadline = savedDeadline;

        const response = await fetch(TASKHANDLER_API, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}` // Aligned Bearer syntax
            },
            body: JSON.stringify(todoData)
        });

        if (!response.ok) {
            const errorData = await response.json();
            throw new Error(errorData.message || response.statusText);
        }

        const resData = await response.json();
        
        // Swap out client tempId placeholders for true backend SQS UUID
        const index = tasksState.findIndex(item => item.taskId === tempId);
        if (index !== -1) {
            tasksState[index].taskId = resData.taskId;
            tasksState[index].createdAt = new Date().toLocaleString([], {hour: '2-digit', minute:'2-digit'});
        }
        localStorage.setItem("cached_todo_list", JSON.stringify(tasksState));
        renderTasksUI();
        
    } catch (error) {
        console.error('Error creating todo:', error);
        // Rollback state cleanly if backend transaction errors
        tasksState = tasksState.filter(item => item.taskId !== tempId);
        renderTasksUI();
        displayGlobalErrorMessage(`Error syncing task with server: ${error.message}`);
    }
}

// Function for update deadline for tasks
async function updateDeadline(taskId, newDeadline) {
  // 🚀 OPTIMISTIC UI: Mutate the tracking array variable immediately
  const targetIndex = tasksState.findIndex(t => t.taskId === taskId);
  let oldDeadline = null;
  if (targetIndex !== -1) {
      oldDeadline = tasksState[targetIndex].deadline;
      tasksState[targetIndex].deadline = newDeadline;
      renderTasksUI();
  }

  try {
    const idToken = localStorage.getItem('authToken');
    if (!idToken) throw new Error('Missing auth token');

    const response = await fetch(`${TASKHANDLER_API}/${taskId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${idToken}` // Aligned Bearer syntax
      },
     body: JSON.stringify({ deadline: newDeadline })
    });

    if (!response.ok) throw new Error(`Failed to update deadline`);
    localStorage.setItem("cached_todo_list", JSON.stringify(tasksState));

  } catch (error) {
    console.error('Error updating deadline:', error);
    // Rollback if needed
    if (targetIndex !== -1) {
        tasksState[targetIndex].deadline = oldDeadline;
        renderTasksUI();
    }
    displayGlobalErrorMessage(`Could not update deadline: ${error.message}`);
  }
}

// Function to update an existing todo text string
async function updateTodo(id) {
    let idToken = localStorage.getItem('authToken');
    if (isTokenExpired(idToken)) {
        await refreshIdToken();
        idToken = localStorage.getItem('authToken');
    }

    const text = document.getElementById(`todo-text-${id}`).value;
    const currentDeadline = selectedDeadline;
    
    // 🚀 OPTIMISTIC UI: Mutate textual representation in state array immediately
    const targetIndex = tasksState.findIndex(t => t.taskId === id);
    let oldText = "";
    if (targetIndex !== -1) {
        oldText = tasksState[targetIndex].taskText;
        tasksState[targetIndex].taskText = text;
        if (currentDeadline) tasksState[targetIndex].deadline = currentDeadline;
        renderTasksUI();
    }

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
        if (currentDeadline) updateData.deadline = currentDeadline;

        const response = await fetch(`${TASKHANDLER_API}/${id}`, {
            method: 'PUT',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${idToken}` // Aligned Bearer syntax
            },
            body: JSON.stringify(updateData)
        });
        
        if (!response.ok) throw new Error(`Failed to update todo`);
        
        if (currentDeadline) resetDeadlineUI();
        localStorage.setItem("cached_todo_list", JSON.stringify(tasksState));
        displaySuccessMessage('Task updated successfully!', id);
        
    } catch (error) {
        console.error('Error updating todo:', error);
        // Rollback state values
        if (targetIndex !== -1) {
            tasksState[targetIndex].taskText = oldText;
            renderTasksUI();
        }
        displayInlineErrorMessage(`Error updating todo: ${error.message}`, id);
        if (currentDeadline) resetDeadlineUI();
    }
}

function displaySuccessMessage(msg, id) {
  const statusEl = document.getElementById(`todo-status-${id}`);
  if (!statusEl) return;
  statusEl.textContent = msg;
  statusEl.style.color = 'green';
  setTimeout(() => { statusEl.textContent = ''; }, 3000);
}

function displayGlobalErrorMessage(message) {
    const errorElement = document.getElementById('error-message');
    if (errorElement) {
        errorElement.textContent = message;
        errorElement.style.display = 'block';
        setTimeout(() => { errorElement.style.display = 'none'; }, 5000);
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

    // 🚀 OPTIMISTIC UI: Splice local tracking array data models instantly
    const backupTasks = [...tasksState];
    tasksState = tasksState.filter(item => item.taskId !== id);
    renderTasksUI();

    try {
        const response = await fetch(`${TASKHANDLER_API}/${id}`, {
            method: 'DELETE',
            headers: { 'Authorization': `Bearer ${idToken}` } // Aligned Bearer syntax
        });
        if (!response.ok) throw new Error(`Failed to delete todo`);
        localStorage.setItem("cached_todo_list", JSON.stringify(tasksState));
    } catch (error) {
        console.error('Error deleting todo:', error);
        // Restoring array state values upon backend failure
        tasksState = backupTasks;
        renderTasksUI();
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

    const logoutUri = "__LOGOUT_URI__";
    window.location.href = `https://${COGNITO_DOMAIN}/logout?client_id=${CLIENT_ID}&logout_uri=${encodeURIComponent(logoutUri)}`;
}

// Window init configurations
window.onload = async () => {
  const path   = window.location.pathname;
  const params = new URLSearchParams(window.location.search);

  if (params.get("code")) {
    await handleOAuthCallback();
    return;
  }

  if (path.includes("dashboard.html")) {
    try {
      // 🚀 STEP 1: Load from local cache immediately (0ms login delay!)
      const localCachedTasks = localStorage.getItem("cached_todo_list");
      if (localCachedTasks) {
          tasksState = JSON.parse(localCachedTasks);
          renderTasksUI();
      }

      let token = localStorage.getItem("authToken") || "";

      if (!token || isTokenExpired(token)) {
        token = await refreshIdToken();
      }

      if (token) {
        // STEP 2: Silently update server side data lists in background paths
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

async function fetchNavbarProfilePicture() {
    const navPic = document.getElementById("navProfilePic");
    const defaultImage = "images/default-profile.png";
    
    try {
        const authToken = localStorage.getItem('authToken');
        if (!authToken) {
            if (navPic) navPic.src = defaultImage;
            return;
        }
        
        const payload = JSON.parse(atob(authToken.split('.')[1]));
        const username = payload['cognito:username'];
        if (!username) {
            if (navPic) navPic.src = defaultImage;
            return;
        }

        const finalUrl = `https://baylenweb-app.xyz/profiles/${username}.jpg`;
        const checkResponse = await fetch(finalUrl, { method: 'HEAD' });

        if (checkResponse.ok) {
            if (navPic) navPic.src = finalUrl;
        } else {
            if (navPic) navPic.src = defaultImage;
        }
        
    } catch (error) {
        console.error("Error loading navbar avatar:", error);
        if (navPic) navPic.src = defaultImage;
    }
}