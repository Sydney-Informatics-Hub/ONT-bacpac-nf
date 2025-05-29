document.addEventListener("DOMContentLoaded", () => {
    const plots = document.querySelectorAll(".bandage_plot_sample");
    const selector = document.getElementById("plotSelector");

    // Get unique sample names from plot IDs
    samples = Array.from(plots).map(smp => smp.id.split(".").slice(1).join("."));
    samples = samples.filter((val, idx, arr) => arr.indexOf(val) === idx);

    // Populate the dropdown
    samples.forEach((smp, idx, arr) => {
        const option = document.createElement("option");
        option.value = smp;
        option.textContent = smp;
        selector.appendChild(option);
        // Set selector value to first item
        if (idx === 0) {
            selector.value = smp;
            plots.forEach(plot => {
                plot.style.display = (plot.id.split(".").slice(1).join(".") === smp) ? "block" : "none";
            })
        }
    });

    // Show selected plot and hide others
    selector.addEventListener("change", () => {
        plots.forEach(plot => {
            plot.style.display = (plot.id.split(".").slice(1).join(".") === selector.value) ? "block" : "none";
        });
    });
});