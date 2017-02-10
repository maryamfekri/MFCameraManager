# CameraManager Features :

● manage camera session 

● get image from camera 

● crop image in a frame

# Requirements :

iOS 8.0+

Xcode 8.1+

Swift 3.0+

---------------------------------------------------------------------------
**Demo :** 

![www gifcreator me_3krqfy](https://cloud.githubusercontent.com/assets/13133764/22628149/36ce4070-ebe4-11e6-9fd9-fdd3fb2ce42f.gif)

---------------------------------------------------------------------------

# Installation :

**CocoaPods :**


```
pod 'MFCameraManager', '~> 1.0'

```

**or download CameraManager.swift file and add it manually to your project**  

# Setup :

Now in your view add a UIView to storyboard view controller or programmetically initiate an UIView which will be your camera preview. then follow steps to display the camera : 

1 - Create a variable of class Camera Manager :

`  var cameraManager = CameraManager() `

2- on your viewDidLoad setup the camera with your UIView created to show the camera preview inside it, and your camera position which its default is back :

`  cameraManager.captureSetup(in: self.cameraView, with: .back) `


3 - in viewWillApear delegate call this method : 

`   cameraManager.startRunning() `

4 - in viewDidDisapear delegate call below method :

` cameraManager.stopRunning() `

5 - to support landscape transitions add below code to viewWillTransition Delegate : 

` cameraManager.transitionCamera() `

----------------------------
- to enable torch mode use below code with level of torch mode default is 1 : 

`cameraManager.enableTorchMode(level: 1)`

- to capture an image showing on camera  : 

```
self.cameraManager.getcroppedImage { (UIImage, error) in

          //your code here to handle with error or if error == nil , get the UIImage 
}
```

- to get the image inside a frame or CGRect , give the frame as a params to getcroppedImage function like below : 

```
self.cameraManager.getcroppedImage(with: self.rectLayer.frame) {  (UIImage, error) in
         
       //your code here to handle with error or if error == nil , get the UIImage 
           
 }

```

# Communication :

- If you found a bug, open an issue.
- If you have a feature request, open an issue.
- If you want to contribute, submit a pull request.
