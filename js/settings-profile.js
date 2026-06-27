function toggleDarkMode() {
    const body = document.body;
    const isDarkMode = body.classList.contains("dark-mode");

    if (isDarkMode) {
        body.classList.remove("dark-mode");
        localStorage.setItem("theme", "light");
    } else {
        body.classList.add("dark-mode");
        localStorage.setItem("theme", "dark");
    }
    updateThemeIcon();
}

function updateThemeIcon() {
    const themeToggle = document.getElementById("theme-toggle");
    const isDarkMode = document.body.classList.contains("dark-mode");
    
    if (themeToggle) {
        const icon = themeToggle.querySelector("i");
        
        if (icon) {
            if (isDarkMode) {
                icon.className = "fas fa-sun";
            } else {
                icon.className = "fas fa-moon";
            }
        }
        
        // Update text labels next to the button seamlessly
        const baseText = isDarkMode ? " Light Mode" : " Dark Mode";
        themeToggle.innerHTML = "";
        if (icon) themeToggle.appendChild(icon);
        themeToggle.appendChild(document.createTextNode(baseText));
    }
}

document.addEventListener("DOMContentLoaded", () => {
    // Read the existing persistent client state cache
    const savedTheme = localStorage.getItem("theme") || "light";
    if (savedTheme === "dark") {
        document.body.classList.add("dark-mode");
    } else {
        document.body.classList.remove("dark-mode");
    }
    updateThemeIcon();
    
    // Bind active toggle execution triggers
    document.getElementById("theme-toggle")?.addEventListener("click", toggleDarkMode);
});