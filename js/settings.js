// Theme functionality
function toggleDarkMode(e) {
    e.preventDefault();
    e.stopPropagation();
    
    const body = document.body;
    // Check if dark mode class is currently active
    const isDark = body.classList.contains("dark-mode");
    
    if (isDark) {
        body.classList.remove("dark-mode");
        localStorage.setItem("theme", "light");
    } else {
        body.classList.add("dark-mode");
        localStorage.setItem("theme", "dark");
    }
    
    updateThemeIcon();
}

function updateThemeIcon() {
    const isDarkMode = document.body.classList.contains("dark-mode");
    const themeToggle = document.getElementById("theme-toggle");
    
    if (themeToggle) {
        const icon = themeToggle.querySelector("i");
        
        // Update font-awesome icons smoothly
        if (icon) {
            if (isDarkMode) {
                icon.className = "fas fa-sun";
            } else {
                icon.className = "fas fa-moon";
            }
        }
        
        // Safely update the button text without destroying the inner <i> tag
        const baseText = isDarkMode ? " Light Mode" : " Dark Mode";
        themeToggle.innerHTML = ""; // Clear
        if (icon) themeToggle.appendChild(icon); // Re-attach icon
        themeToggle.appendChild(document.createTextNode(baseText)); // Append text string
    }
}

// Initialize theme state on layout render
function initializeTheme() {
    const savedTheme = localStorage.getItem("theme") || "light";
    
    if (savedTheme === "dark") {
        document.body.classList.add("dark-mode");
    } else {
        document.body.classList.remove("dark-mode");
    }
    
    updateThemeIcon();
    
    const themeToggle = document.getElementById("theme-toggle");
    if (themeToggle) {
        // Remove duplicate listeners if initialized multi-times
        themeToggle.removeEventListener("click", toggleDarkMode);
        themeToggle.addEventListener("click", toggleDarkMode);
    }
}

// Initialize when DOM content has finished downloading
document.addEventListener("DOMContentLoaded", function() {
    initializeTheme();
    
    // Dropdown visibility routing interactions
    const dropdownToggle = document.getElementById("dropdown-toggle");
    const dropdownMenu = document.getElementById("dropdown-menu");
    
    if (dropdownToggle && dropdownMenu) {
        dropdownToggle.addEventListener("click", function(e) {
            e.stopPropagation();
            dropdownMenu.classList.toggle("show");
        });
        
        // Close interactive dropdown pane if user clicks outside context area
        document.addEventListener("click", function(e) {
            if (!e.target.closest(".dropdown")) {
                dropdownMenu.classList.remove("show");
            }
        });
    }
});