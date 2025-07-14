const apiUrl = 'https://gxfhualsxc.execute-api.us-east-1.amazonaws.com/PROD/zerefapi';

document.getElementById('add-task-btn').addEventListener('click', async function() {
    const taskText = document.getElementById('new-task').value;
    if (taskText === '') {
        alert('Please enter a task.');
        return;
    }

    const taskId = new Date().getTime().toString();

    const response = await fetch(apiUrl, {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ taskId, taskText })
    });

    const result = await response.json();
    if (response.status === 200) {
        addTaskToUI(taskId, taskText);
        document.getElementById('new-task').value = '';
    } else {
        alert('Failed to add task: ' + result.message);
    }
});

window.onload = async function() {
    const response = await fetch(apiUrl);
    const tasks = await response.json();

    tasks.forEach(task => {
        addTaskToUI(task.taskId, task.taskText);
    });
};

function addTaskToUI(taskId, taskText) {
    const li = document.createElement('li');
    li.dataset.taskId = taskId;

    const taskSpan = document.createElement('span');
    taskSpan.textContent = taskText;

    // Edit Button
    const editBtn = document.createElement('button');
    editBtn.textContent = 'Edit';
    editBtn.onclick = function() {
        const newTaskText = prompt('Edit Task:', taskText);
        if (newTaskText) {
            updateTask(taskId, newTaskText);
            taskSpan.textContent = newTaskText;
        }
    };

    // Delete Button
    const removeBtn = document.createElement('button');
    removeBtn.textContent = 'Remove';
    removeBtn.onclick = async function() {
        const deleteResponse = await fetch(apiUrl, {
            method: 'DELETE',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ taskId })
        });

        if (deleteResponse.status === 200) {
            li.remove();
        } else {
            alert('Failed to delete task');
        }
    };

    li.appendChild(taskSpan);
    li.appendChild(editBtn);
    li.appendChild(removeBtn);
    document.getElementById('task-list').appendChild(li);
}

async function updateTask(taskId, taskText) {
    const response = await fetch(apiUrl, {
        method: 'POST', // Assuming we're using the same POST method to update the task
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({ taskId, taskText })
    });

    if (response.status !== 200) {
        alert('Failed to update task');
    }
}