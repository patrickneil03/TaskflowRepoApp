function toggleDarkMode() {
    const body = document.body;
    const isDarkMode = body.getAttribute("data-theme") === "dark";

    body.setAttribute("data-theme", isDarkMode ? "light" : "dark");
    localStorage.setItem("theme", isDarkMode ? "light" : "dark");
    updateThemeIcon();
}

function updateThemeIcon() {
    const icons = document.querySelectorAll("#theme-toggle i, #theme-toggle-settings i");
    const isDarkMode = document.body.getAttribute("data-theme") === "dark";
    
    icons.forEach(icon => {
        if (icon.classList.contains("fa-moon")) {
            icon.style.display = isDarkMode ? "none" : "inline-block";
        }
        if (icon.classList.contains("fa-sun")) {
            icon.style.display = isDarkMode ? "inline-block" : "none";
        }
    });
}

document.addEventListener("DOMContentLoaded", () => {
    const savedTheme = localStorage.getItem("theme") || "light";
    document.body.setAttribute("data-theme", savedTheme);
    updateThemeIcon();
    
    document.getElementById("theme-toggle")?.addEventListener("click", toggleDarkMode);
    document.getElementById("theme-toggle-settings")?.addEventListener("click", toggleDarkMode);
});