"use strict";

document.addEventListener("DOMContentLoaded", () => {
  if (!document.fullscreenEnabled) {
    return;
  }

  const frames = [];
  document.querySelectorAll("figure img.expandable-diagram").forEach((image) => {
    const frame = document.createElement("div");
    frame.className = "diagram-image-frame";
    image.parentNode.insertBefore(frame, image);
    frame.appendChild(image);

    const button = document.createElement("button");
    button.type = "button";
    button.className = "diagram-fullscreen-button";
    button.textContent = "Full screen";
    button.setAttribute("aria-label", "View diagram full screen");
    button.setAttribute("aria-pressed", "false");
    frame.appendChild(button);
    frames.push({ frame, button });

    button.addEventListener("click", () => {
      const action = document.fullscreenElement === frame
        ? document.exitFullscreen()
        : frame.requestFullscreen();
      action.catch(() => undefined);
    });
  });

  document.addEventListener("fullscreenchange", () => {
    frames.forEach(({ frame, button }) => {
      const active = document.fullscreenElement === frame;
      button.textContent = active ? "Exit full screen" : "Full screen";
      button.setAttribute("aria-label", button.textContent);
      button.setAttribute("aria-pressed", String(active));
    });
  });
});
