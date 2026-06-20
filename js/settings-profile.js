function toggleDarkMode() {
    const body = document.body;
    const isDarkMode = body.getAttribute("data-theme") === "dark";

    body.setAttribute("data-theme", isDarkMode ? "light" : "dark");
    localStorage.setItem("theme", isDarkMode ? "light" : "dark");
    updateThemeIcon();
}

function updateThemeIcon() {
    const icons = document.querySelectorAll("#theme-toggle i, #theme-toggle-settings i");
    const labelSpan = document.querySelector("#theme-toggle span");
    const isDarkMode = document.body.getAttribute("data-theme") === "dark";
    
    // Smoothly swap icon metrics classes
    icons.forEach(icon => {
        if (isDarkMode) {
            icon.className = "fas fa-sun";
        } else {
            icon.className = "fas fa-moon";
        }
    });

    // Update context text cleanly
    if (labelSpan) {
        labelSpan.textContent = isDarkMode ? "Light Mode" : "Dark Mode";
    }
}

document.addEventListener("DOMContentLoaded", () => {
    const savedTheme = localStorage.getItem("theme") || "light";
    document.body.setAttribute("data-theme", savedTheme);
    updateThemeIcon();
    
    document.getElementById("theme-toggle")?.addEventListener("click", toggleDarkMode);
    document.getElementById("theme-toggle-settings")?.addEventListener("click", toggleDarkMode);
});