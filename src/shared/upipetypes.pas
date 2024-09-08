unit upipetypes;

interface

uses system.Types;

const
  //When callback function fires it returns a messagetype which is an integer
  //representing the type of message that occures
  MSG_PIPESENT       = 1000; //if a message is sent over through the pipe
  MSG_PIPECONNECT    = 1001; //if a pipe client is connected
  MSG_PIPEDISCONNECT = 1002; //if a pipeclient is disconnected
  MSG_PIPEMESSAGE    = 1003; //if a message is sent through the pipe
  MSG_PIPEERROR      = 1004; //if an error is raised
  MSG_GETPIPECLIENTS = 1005; //if call is made to GetConnectedPipeClients

type
  TCallBackFunction =
    function(msgType: integer; //this is the messagetype constant
      var pipeID: Int32;     //The clients pipeID
      var answer: PAnsiChar;   //an answer composed as a string
      var param: DWORD         //some parameter as a DWORD in most cases the string length
    ):boolean; stdcall;

implementation

end.
