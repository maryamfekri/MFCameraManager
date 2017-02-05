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

- to enable torch mode use below code with level of torch mode default is 1 : 
`cameraManager.enableTorchMode(level: 1)`

- to capture an image showing on camera  : 
` self.cameraManager.getcroppedImage { (UIImage, error) in
            //your code here to handle with error or if error == nil , get the UIImage 
        }`

- to get the image inside a frame or CGRect , give the frame as a params to getcroppedImage function like below : 
`self.cameraManager.getcroppedImage(with: self.rectLayer.frame) {
           //your code here to handle with error or if error == nil , get the UIImage 
        }`
