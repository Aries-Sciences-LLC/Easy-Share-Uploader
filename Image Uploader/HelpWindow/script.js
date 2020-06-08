let index = 0;
let instructions = ["Welcome, please click the buttons to go through the instructions.",
                    "This app is where you take any local image and create a direct, online url for it which can be easily applicable for any use, requires no security precautions, and never dissolves.",
                    "First, there are three ways to select an image, by dragging and dropping the image file into the big view, by clicking on the upload button to open the file browser, by clicking file -> open, or by holding something while dragging and dropping the image file into the app icon.",
                    "There is also a feature that lets you create an image from the built-in webcam.",
                    "Once the image is succesfully loaded in, it's info appears on the screen.",
                    "After that, once the start button is clicked, a popup will display asking you to select the website you want to host your image. Please note, Google does require your Google login. However, we do not save any information and everything gets immediatly sent to their authentication system.",
                    "Once the service is selected, it will load for 2 to 3 seconds, and present you with the link, which you can share through many other apps such as Messages, Mail, etc.",
                    "Please note that once you make a link, that link, along with the image, gets saved in in the history section which you can look back to anytime, and edit.",
                    "You are allowed to create as much links as you want and once you create one, click create another to do it again.",
                    "Have fun, and thank you for using our service, it means a lot to us that you are using it. And whenever you want to open this help page again, just click help on the menubar and Image Uploader Help"];

document.getElementById('leftArrow').onclick = function() {
  if(index != 0) {
    index -= 1;
    updateInstructions();
  }
}

document.getElementById('rightArrow').onclick = function() {
  if(index != instructions.length - 1) {
    index += 1;
    updateInstructions();
  }
}

function updateInstructions() {
  document.getElementById('instructions').classList.remove("fade-in");
  document.getElementById('instructions').classList.add("fade-out");
  setTimeout(function() {
    document.getElementById('instructions').innerHTML = instructions[index];
    document.getElementById('instructions').classList.remove("fade-out");
    document.getElementById('instructions').classList.add("fade-in");
  }, 500);
}

updateInstructions();
