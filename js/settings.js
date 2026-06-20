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