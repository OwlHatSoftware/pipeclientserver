# PipeClientServer
 Implementation of a messagingservice based on Russel Libby's pipes unit (copy included)
 This messagingservice is build around his library. 
 I went for a platform independent approach, so there are two dll's which must be build beforehand (PipeClient.dll and PipeServer.dll the prebuild are available here). These dll's must be present in your app directory (where the .exe resides) or 
 they must be somewhere on your system where they can be found by any program system32 and/or sysWOW64 on Windows.
 I have only tested this implementation on 32bit and 64bit windows. I don't know if the pipes unit is crossplatform, i think it will only work on Windows but I am not sure.
 There is a demo of a client, a server and a (windows)service implementation in the \demo directory. For the demo to work correctly you need the json library superobject: https://github.com/hgourvest/superobject
 or use my fork: https://github.com/OwlHatSoftware/superobject. 
 
 Have fun coding and enjoy using it!! 
 
# About the unit Pipes.pas
 The pipes unit can be found on: https://github.com/marsupilami79/DelphiPipes
 I included a copy of it in this source and it resides in the src\shared directory
 The license of the Pipes unit is 'Free' as stated in the license file: https://github.com/marsupilami79/DelphiPipes/blob/master/LICENSE
 
# License
 This software is published under MIT License and thus can be copied modified etc. free of charge and without any warranty.
 
 
