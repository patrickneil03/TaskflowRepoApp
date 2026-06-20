// Theme functionality
function toggleDarkMode(e) {
    if (e) {
        e.preventDefault();
        e.stopPropagation();
    }
    
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
            icon.className = isDarkMode ? "fas fa-sun" : "fas fa-moon";
        }
        
        if (text) {
            text.textContent = isDarkMode ? "Light Mode" : "Dark Mode";
        }
    }
}

// Initialize theme when DOM is fully loaded
document.addEventListener("DOMContentLoaded", function() {
    const savedTheme = localStorage.getItem("theme") || "light";
    document.body.setAttribute("data-theme", savedTheme);
    updateThemeIcon();
    
    const themeToggle = document.getElementById("theme-toggle");
    if (themeToggle) {
        themeToggle.addEventListener("click", toggleDarkMode);
    }
});