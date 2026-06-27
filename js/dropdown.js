document.addEventListener("DOMContentLoaded", () => {
    const dropdownToggle = document.getElementById("dropdown-toggle");
    const dropdownMenu = document.getElementById("dropdown-menu");
    
    if (dropdownToggle && dropdownMenu) {
        dropdownToggle.addEventListener("click", (e) => {
            e.stopPropagation();
            dropdownMenu.classList.toggle("show");
        });
        
        document.addEventListener("click", (e) => {
            if (!e.target.closest(".dropdown")) {
                dropdownMenu.classList.remove("show");
            }
        });
    }
});