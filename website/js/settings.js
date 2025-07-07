// Theme functionality
function toggleDarkMode(e) {
    e.preventDefault();
    e.stopPropagation();
    
    const body = document.body;
    const currentTheme = body.getAttribute("data-theme") || "light";
    const newTheme = currentTheme === "dark" ? "light" : "dark";
    
    body.setAttribute("data-theme", newTheme);
    localStorage.setItem("theme", newTheme);
    updateThemeIcon();
}

function updateThemeIcon() {
    const isDarkMode = document.body.getAttribute("data-theme") === "dark";
    const themeToggle = document.getElementById("theme-toggle");
    
    if (themeToggle) {
        const icon = themeToggle.querySelector("i");
        const text = themeToggle.querySelector("span");
        
        if (icon) {
            icon.classList.toggle("fa-moon", !isDarkMode);
            icon.classList.toggle("fa-sun", isDarkMode);
        }
        
        if (text) {
            text.textContent = isDarkMode ? "Light Mode" : "Dark Mode";
        }
    }
}

// Initialize theme
function initializeTheme() {
    const savedTheme = localStorage.getItem("theme") || "light";
    document.body.setAttribute("data-theme", savedTheme);
    updateThemeIcon();
    
    // Add event listener
    const themeToggle = document.getElementById("theme-toggle");
    if (themeToggle) {
        themeToggle.addEventListener("click", toggleDarkMode);
    }
}

// Initialize when DOM is loaded
document.addEventListener("DOMContentLoaded", function() {
    initializeTheme();
    
    // Your existing dropdown code
    const dropdownToggle = document.getElementById("dropdown-toggle");
    const dropdownMenu = document.getElementById("dropdown-menu");
    
    if (dropdownToggle && dropdownMenu) {
        dropdownToggle.addEventListener("click", function(e) {
            e.stopPropagation();
            dropdownMenu.classList.toggle("show");
        });
        
        document.addEventListener("click", function() {
            dropdownMenu.classList.remove("show");
        });
    }
});