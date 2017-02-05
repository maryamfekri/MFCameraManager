# CameraManager
● manage camera session 

● get image from camera 

● cropp image from a rect given to the class

**Screenshots :** 

**How to use :**
1 - Create a variable of class Camera Manager :
`  var cameraManager = CameraManager() `
2 - in viewWillApear delegate call this method : 
`   cameraManager.startRunning() `
3 - in viewDidDisapear delegate call below method :
` cameraManager.stopRunning() `
4 - to support landscape transitions add below code to viewWillTransition Delegate : 
` cameraManager.transitionCamera() `
