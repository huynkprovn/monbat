using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO.Ports;
using System.Diagnostics;
using XBee;

namespace XBee
{
    
    public class XBee : XBeeConstants
    {
        public XBee()
        {
            _pos = 0;
            _escape = false;
            _checksumTotal = 0;
            _nextFrameId = 0;
            
            _response = new XBeeResponse();
            _response.init();
            _response.setFrameData(_responseFrameData);
            // default
            //_serial = &Serial;
        }


        /**
	    * Reads all available serial bytes until a packet is parsed, an error occurs, or the buffer is empty.
   	    * You may call <i>xbee</i>.getResponse().isAvailable() after calling this method to determine if
	    * a packet is ready, or <i>xbee</i>.getResponse().isError() to determine if
	    * a error occurred.
	    * <p/>
	    * This method should always return quickly since it does not wait for serial data to arrive.
	    * You will want to use this method if you are doing other timely stuff in your loop, where
	    * a delay would cause problems.
	    * NOTE: calling this method resets the current response, so make sure you first consume the
	    * current response
	    */
        public void readPacket() 
        {
            // reset previous response
	        if (_response.isAvailable() || _response.isError())
            {
                // discard previous packet and start over
                resetResponse();
            }
            
            while (available()) 
            {
                _b = read();
                
                if (_pos > 0 && _b == START_BYTE && ATAP == 2)
                {
                    // new packet start before previous packeted completed -- discard previous packet and start over
                    _response.setErrorCode(UNEXPECTED_START_BYTE);
        	        return;
                }

        		if (_pos > 0 && _b == ESCAPE)
                {
                    if (available())
                    {
                        _b = read();
                        _b = (byte)(0x20 ^ _b);
                    }
                    else 
                    {
                        // escape byte.  next byte will be
				        _escape = true;
				        continue;
			        }
		        }

        		if (_escape == true)
                {
		        	_b = (byte)(0x20 ^ _b);
			        _escape = false;
		        }

		        // checksum includes all bytes starting with api id
		        if (_pos >= API_ID_INDEX)
                {
                    _checksumTotal+= _b;
		        }

                switch (_pos)
                {
			        case 0 :
		                if (_b == START_BYTE)
                        {
                            _pos++;
		                }
                        break;

			        case 1 :
				        // length msb
				        _response.setMsbLength(_b);
				        _pos++;
                        break;

        			case 2 :
		        		// length lsb
				        _response.setLsbLength(_b);
        				_pos++;
                        break;

        			case 3 :
		        		_response.setApiId(_b);
				        _pos++;
                        break;


                    default :
        				// starts at fifth byte

		        		if (_pos > MAX_FRAME_DATA_SIZE)
                        {
				        	// exceed max size.  should never occur
					        _response.setErrorCode(PACKET_EXCEEDS_BYTE_ARRAY_LENGTH);
					        return;
				        }

        				// check if we're at the end of the packet
		        		// packet length does not include start, length, or checksum bytes, so add 3
				        if (_pos == (_response.getPacketLength() + 3))
                        {
					        // verify checksum

	        				//std::cout << "read checksum " << static_cast<unsigned int>(b) << " at pos " << static_cast<unsigned int>(_pos) << std::endl;
                                
					        if ((_checksumTotal & 0xff) == 0xff)
                            {
						        _response.setChecksum(_b);
						        _response.setAvailable(true);

						        _response.setErrorCode(NO_ERROR);
					        }
                            else
                            {
						        // checksum failed
						        _response.setErrorCode(CHECKSUM_FAILURE);
        					}

		        			// minus 4 because we start after start,msb,lsb,api and up to but not including checksum
				        	// e.g. if frame was one byte, _pos=4 would be the byte, pos=5 is the checksum, where end stop reading
					        _response.setFrameLength((byte)(_pos - 4));

					        // reset state vars
					        _pos = 0;

        					_checksumTotal = 0;

				        	return;
		        		}
                        else
                        {
                            // add to packet array, starting with the fourth byte of the apiFrame
					        _response.getFrameData()[_pos - 4] = _b;
					        _pos++;
				        }
                        break;
                }
            }
        }

        /**
        * Waits a maximum of <i>timeout</i> milliseconds for a response packet before timing out; returns true if packet is read.
        * Returns false if timeout or error occurs.
        */
        public bool readPacket(int timeout)
        {
            if (timeout < 0) 
            {
                return false;
	        }
            Stopwatch stopWatch = new Stopwatch();
            stopWatch.Start();
            
            while (stopWatch.ElapsedMilliseconds < timeout)
            {
                readPacket();
                if (getResponse().isAvailable())
                {
                    return true;
                } 
                else if (getResponse().isError())
                {
                    return false;
                }
            }

            stopWatch.Stop();
            // timed out
            return false;
        }



        /**
        * Reads until a packet is received or an error occurs.
        * Caution: use this carefully since if you don't get a response, your Arduino code will hang on this
        * call forever!! often it's better to use a timeout: readPacket(int)
        */
        public void readPacketUntilAvailable()
        {
            while (!(getResponse().isAvailable() || getResponse().isError()))
            {
                // read some more
                readPacket();
	        }
        }


        /**
        * Starts the serial connection at the supplied baud rate
        */
        public void begin(string portCOM, int baud)
        {
            _serial = new SerialPort(portCOM,baud,Parity.None,8,StopBits.One);

            _serial.DtrEnable = false;
            _serial.RtsEnable = false;
            _serial.ReadTimeout = 100;
            _serial.WriteTimeout = 100;
            if (!_serial.IsOpen)
            {
                _serial.Open();
            }
            
        }


        public void close()
        {
            _serial.Close();
        }

        
        
        public XBeeResponse getResponse()
        {
            return _response;
        }

        
        public void getResponse(ref XBeeResponse response)
        {
            response.setMsbLength(_response.getMsbLength());
            response.setLsbLength(_response.getLsbLength());
            response.setApiId(_response.getApiId());
            response.setFrameLength(_response.getFrameDataLength());

            // Eliminar punteros de la siguiente funcion *********************************
            //response.setFrameData(_response.getFrameData());
        }

        /**
	    * Sends a XBeeRequest (TX packet) out the serial port
	    */
        public void send(XBeeRequest request)
        {
            // the new new deal

        	sendByte(START_BYTE, false);

        	// send length
	        byte msbLen = (byte)(((request.getFrameDataLength() + 2) >> 8) & 0xff);
	        byte lsbLen = (byte)((request.getFrameDataLength() + 2) & 0xff);

	        sendByte(msbLen, true);
        	sendByte(lsbLen, true);

	        // api id
	        sendByte(request.getApiId(), true);
	        sendByte(request.getFrameId(), true);

        	byte checksum = 0;

	        // compute checksum, start at api id
	        checksum+= request.getApiId();
        	checksum+= request.getFrameId();

	        for (byte i = 0; i < request.getFrameDataLength(); i++) {
		        sendByte(request.getFrameData(i), true);
		        checksum+= request.getFrameData(i);
        	}

	        // perform 2s complement
	        checksum = (byte)(0xff - checksum);

	        // send checksum
	        sendByte(checksum, true);

	        // send packet (Note: prior to Arduino 1.0 this flushed the incoming buffer, which of course was not so great)
	        flush();
        }


        /**
	    * Returns a sequential frame id between 1 and 255
	    */
	    public byte getNextFrameId()
        {
            _nextFrameId++;

            if (_nextFrameId == 0)
            {
                // can't send 0 because that disables status response
                _nextFrameId = 1;
            }

            return _nextFrameId;
        }


        /**
        * Specify the serial port.  Only relevant for Arduinos that support multiple serial ports (e.g. Mega)
	    
        void setSerial(SerialPort serial)
        {
            _serial = serial;
        }
        */


        private bool available()
        {
            return (_serial.BytesToRead > 0);
        }

        private byte read()
        {
            return (byte)_serial.ReadByte();
        }

        private void flush()
        {
            _serial.DiscardInBuffer();
        }
    	
        private void write(byte val)
        {
            // combinar junto con sendByte en una sola funcion donde se envia toda el array de la trama
            byte[] val2 = new byte[1];
            val2[0] = val;
            _serial.Write(val2,0,1);
        }
	    
        public void sendByte(byte b, bool escape)
        {
            if (escape && (b == START_BYTE || b == ESCAPE || b == XON || b == XOFF))
            {
                //		std::cout << "escaping byte [" << toHexString(b) << "] " << std::endl;
                write(ESCAPE);
                write((byte)(b ^ 0x20));
            }
            else
            {
                write(b);
            }
        }
        
        private void resetResponse() 
        {
            _pos = 0;
            _escape = false;
            _response.reset();
        }

        public XBeeRequest request;

    	private XBeeResponse _response;
    	private bool _escape;
    	// current packet position for response.  just a state variable for packet parsing and has no relevance for the response otherwise
    	private byte _pos;
    	// last byte read
    	private byte _b;
    	private byte _checksumTotal;
    	private byte _nextFrameId;
    	// buffer for incoming RX packets.  holds only the api specific frame data, starting after the api id byte and prior to checksum
    	private byte[] _responseFrameData = new byte[MAX_FRAME_DATA_SIZE];
    	private SerialPort _serial;  //manejador del puerto serie que conecta al modulo Xbee
    }

    public class XBeeResponse : XBeeConstants
    {
        /**
	    * Default constructor
	    */
        public XBeeResponse()
        {
        }
        
        
        /**
         * Returns Api Id of the response
         */
        public byte getApiId()
        {
            return _apiId;
        }


        public void setApiId(byte apiId)
        {
            _apiId = apiId;
        }
        

        /**
         * Returns the MSB length of the packet
         */
        public byte getMsbLength()
        {
            return _msbLength;
        }


        public void setMsbLength(byte msbLength)
        {
            _msbLength = msbLength;
        }


        /**
         * Returns the LSB length of the packet
         */
        public byte getLsbLength()
        {
            return _lsbLength;
        }


        public void setLsbLength(byte lsbLength)
        {
            _lsbLength = lsbLength;
        }


        /**
         * Returns the packet checksum
         */
        public byte getChecksum()
        {
            return _checksum;
        }


        public void setChecksum(byte checksum)
        {
            _checksum = checksum;
        }


        /**
         * Returns the length of the frame data: all bytes after the api id, and prior to the checksum
         * Note up to release 0.1.2, this was incorrectly including the checksum in the length.
         */
        public byte getFrameDataLength()
        {
            return _frameLength;
        }

        public void setFrameLength(byte frameLength) 
        {
            _frameLength = frameLength;
        }


        public void setFrameData(byte[] frameData)
        {
            _frameData = frameData;
        }


        /**
         * Returns the buffer that contains the response.
         * Starts with byte that follows API ID and includes all bytes prior to the checksum
         * Length is specified by getFrameDataLength()
         * Note: Unlike Digi's definition of the frame data, this does not start with the API ID..
         * The reason for this is all responses include an API ID, whereas my frame data
         * includes only the API specific data.
         */
        public byte[] getFrameData()
        {
            return _frameData;
        }

        
        // to support future 65535 byte packets I guess
        /**
         * Returns the length of the packet
         */
        public UInt16 getPacketLength()
        {
            return (UInt16)(((_msbLength << 8) & 0xff) + (_lsbLength & 0xff));
        }


        /**
         * Resets the response to default values
         */
        public void reset()
        { 
            init();
	        _apiId = 0;
	        _msbLength = 0;
	        _lsbLength = 0;
	        _checksum = 0;
	        _frameLength = 0;

	        _errorCode = NO_ERROR;

	        for (int i = 0; i < MAX_FRAME_DATA_SIZE; i++) 
            {
		        getFrameData()[i] = 0;
            }
        }
        
        
        /**
         * Initializes the response
         */
        public void init()
        {
            _complete = false;
	        _errorCode = NO_ERROR;
        	_checksum = 0;
        }


        /**
	    * Call with instance of ZBTxStatusResponse class only if getApiId() == ZB_TX_STATUS_RESPONSE
	    * to populate response
        */
        public void getZBTxStatusResponse(ref XBeeResponse response)
        {
	        response.setFrameData(getFrameData());
	        setCommon(ref response);
        }


	    /**
	    * Call with instance of ZBRxResponse class only if getApiId() == ZB_RX_RESPONSE
	    * to populate response
	    */
        public void getZBRxResponse(ref ZBRxResponse response)
        {
	        setCommon(ref response);
            response.getRemoteAddress64().setMsb((UInt32)(((UInt32)(getFrameData()[0]) << 24) + ((UInt32)(getFrameData()[1]) << 16) + ((UInt16)(getFrameData()[2]) << 8) + getFrameData()[3]));
	        response.getRemoteAddress64().setLsb((UInt32)(((UInt32)(getFrameData()[4]) << 24) + ((UInt32)(getFrameData()[5]) << 16) + ((UInt16)(getFrameData()[6]) << 8) + (getFrameData()[7])));
        }


	    /**
	    * Call with instance of ZBRxIoSampleResponse class only if getApiId() == ZB_IO_SAMPLE_RESPONSE
	    * to populate response
	    */
        public void getZBRxIoSampleResponse(ref ZBRxIoSampleResponse response)
        {
	        setCommon(ref response);
            response.getRemoteAddress64().setMsb((UInt32)(((UInt32)(getFrameData()[0]) << 24) + ((UInt32)(getFrameData()[1]) << 16) + ((UInt16)(getFrameData()[2]) << 8) + getFrameData()[3]));
	        response.getRemoteAddress64().setLsb((UInt32)(((UInt32)(getFrameData()[4]) << 24) + ((UInt32)(getFrameData()[5]) << 16) + ((UInt16)(getFrameData()[6]) << 8) + (getFrameData()[7])));
        }


        /**
	    * Call with instance of AtCommandResponse only if getApiId() == AT_COMMAND_RESPONSE
	    */
        public void getAtCommandResponse(ref AtCommandResponse response)
        {
	        response.setFrameData(getFrameData());
	        setCommon(ref response);
        }


	    /**
	    * Call with instance of RemoteAtCommandResponse only if getApiId() == REMOTE_AT_COMMAND_RESPONSE
	    */
        public void getRemoteAtCommandResponse(ref RemoteAtCommandResponse response)
        {
	        setCommon(ref response);
            response.getRemoteAddress64().setMsb((UInt32)(((UInt32)(getFrameData()[0]) << 24) + ((UInt32)(getFrameData()[1]) << 16) + ((UInt16)(getFrameData()[2]) << 8) + getFrameData()[3]));
	        response.getRemoteAddress64().setLsb((UInt32)(((UInt32)(getFrameData()[4]) << 24) + ((UInt32)(getFrameData()[5]) << 16) + ((UInt16)(getFrameData()[6]) << 8) + (getFrameData()[7])));
        }


	    /**
	    * Call with instance of ModemStatusResponse only if getApiId() == MODEM_STATUS_RESPONSE
        */
        public void getModemStatusResponse(ref XBeeResponse modemStatusResponse)
        {
            //ModemStatusResponse* modem = static_cast<ModemStatusResponse*>(&modemStatusResponse);

        	// pass pointer array to subclass
	        modemStatusResponse.setFrameData(getFrameData());
	        setCommon(ref modemStatusResponse);

        }


	    /**
	    * Returns true if the response has been successfully parsed and is complete and ready for use
	    */
        public bool isAvailable()
        {
            return _complete;
        }


        public void setAvailable(bool complete)
        {
            _complete = complete;
        }


	    /**
	    * Returns true if the response contains errors
	    */
        public bool isError()
        {
            return _errorCode > 0;
        }


	    /**
	    * Returns an error code, or zero, if successful.
	    * Error codes include: CHECKSUM_FAILURE, PACKET_EXCEEDS_BYTE_ARRAY_LENGTH, UNEXPECTED_START_BYTE
	    */
        public byte getErrorCode()
        {
            return _errorCode;
        }


        public void setErrorCode(byte errorCode)
        {
            _errorCode = errorCode;
        }


        // Se ha cambiado el puntero por un array
        protected byte[] _frameData = new byte[MAX_FRAME_DATA_SIZE];

        private void setCommon(ref XBeeResponse target)
        {
            target.setApiId(getApiId());
	        target.setAvailable(isAvailable());
	        target.setChecksum(getChecksum());
	        target.setErrorCode(getErrorCode());
	        target.setFrameLength(getFrameDataLength());
	        target.setMsbLength(getMsbLength());
	        target.setLsbLength(getLsbLength());
        }


        private void setCommon(ref ZBRxResponse target)
        {
            target.setApiId(getApiId());
	        target.setAvailable(isAvailable());
	        target.setChecksum(getChecksum());
	        target.setErrorCode(getErrorCode());
	        target.setFrameLength(getFrameDataLength());
	        target.setMsbLength(getMsbLength());
	        target.setLsbLength(getLsbLength());
        }


        private void setCommon(ref ZBRxIoSampleResponse target)
        {
            target.setApiId(getApiId());
	        target.setAvailable(isAvailable());
	        target.setChecksum(getChecksum());
	        target.setErrorCode(getErrorCode());
	        target.setFrameLength(getFrameDataLength());
	        target.setMsbLength(getMsbLength());
	        target.setLsbLength(getLsbLength());
        }


        private void setCommon(ref AtCommandResponse target)
        {
            target.setApiId(getApiId());
            target.setAvailable(isAvailable());
            target.setChecksum(getChecksum());
            target.setErrorCode(getErrorCode());
            target.setFrameLength(getFrameDataLength());
            target.setMsbLength(getMsbLength());
            target.setLsbLength(getLsbLength());
        }


        private void setCommon(ref RemoteAtCommandResponse target)
        {
            target.setApiId(getApiId());
	        target.setAvailable(isAvailable());
	        target.setChecksum(getChecksum());
	        target.setErrorCode(getErrorCode());
	        target.setFrameLength(getFrameDataLength());
	        target.setMsbLength(getMsbLength());
	        target.setLsbLength(getLsbLength());
        }


        private byte _apiId;
        private byte _msbLength;
        private byte _lsbLength;
        private byte _checksum;
        private byte _frameLength;
        private bool _complete;
        private byte _errorCode;
    
    }



    public class XBeeAddress : XBeeConstants
    {
        public XBeeAddress()
        {
        }
    }



    /**
    * Represents a 64-bit XBee Address
    */
    public class XBeeAddress64 : XBeeAddress 
    {
        public XBeeAddress64(UInt32 msb, UInt32 lsb)
        {
            _msb = msb;
	        _lsb = lsb;
        }


	    public XBeeAddress64()
        {
        }

	    public UInt32 getMsb()
        {
            return _msb;
        }


	    public UInt32 getLsb()
        {
            return _lsb;
        }


	    public void setMsb(UInt32 msb)
        {
            _msb = msb;
        }


	    public void setLsb(UInt32 lsb)
        {
            _lsb = lsb;
        }
    
        private UInt32 _msb;
	    private UInt32 _lsb;
    }



    /**
    * This class is extended by all Responses that include a frame id
    */
    public class FrameIdResponse : XBeeResponse
    {
        public FrameIdResponse()
        {
        }


	    public byte getFrameId()
        {
            return getFrameData()[0];
        }
        
        
        private byte _frameId;
    }



    /**
    * Common functionality for both Series 1 and 2 data RX data packets
    */
    public class RxDataResponse : XBeeResponse
    {
        public RxDataResponse()
        {
        }
            
        
        /**
	    * Returns the specified index of the payload.  The index may be 0 to getDataLength() - 1
	    * This method is deprecated; use byte* getData()
	    */
        public byte getData(int index)
        {
            return getFrameData()[getDataOffset() + index];
        }


        /**
        * Returns the payload array.  This may be accessed from index 0 to getDataLength() - 1
        public byte[] getData()
        {
            byte res = 0x00;
            return &res;
        }
        */



        /**
        * Returns the length of the payload
        */
	    public virtual byte getDataLength()
        {
            return (byte)(getPacketLength() - getDataOffset() - 1);
        }

	    
        /**
	    * Returns the position in the frame data where the data begins
	    */
	    public virtual byte getDataOffset()
        {
            return 11;
        }

    }


    /**
    * Represents a Series 2 TX status packet
    */
    public class ZBTxStatusResponse : FrameIdResponse 
    {
	    public ZBTxStatusResponse()
        {
        }


		public UInt16 getRemoteAddress()
        {
            return  (UInt16)((UInt16)(getFrameData()[1] << 8) + getFrameData()[2]);
        }


		public byte getTxRetryCount()
        {
            return getFrameData()[3];
        }


		public byte getDeliveryStatus()
        {
            return getFrameData()[4];
        }


		public byte getDiscoveryStatus()
        {
            return getFrameData()[5];
        }


		public bool isSuccess()
        {
            return getDeliveryStatus() == SUCCESS;
        }

    }

    /**
    * Represents a Series 2 RX packet
    */
    public class ZBRxResponse : RxDataResponse
    {
        public ZBRxResponse()
        {
            _remoteAddress64 = new XBeeAddress64();
        }


        public XBeeAddress64 getRemoteAddress64()
        {
            return _remoteAddress64;
        }
        

        public UInt16 getRemoteAddress16()
        {
            return 	(UInt16)((UInt16)(getFrameData()[8] << 8) + getFrameData()[9]);
        }


        public byte getOption()
        {
            return getFrameData()[10];
        }


        public override byte getDataLength()
        {
            return (byte)(getPacketLength() - getDataOffset() - 1);
        }


	    // frame position where data starts
	    public override byte getDataOffset()
        {
            return 11;
        }

                
        private XBeeAddress64 _remoteAddress64;
    }

    
    
    /**
    * Represents a Series 2 RX I/O Sample packet
    */
    public class ZBRxIoSampleResponse : ZBRxResponse 
    {
        public ZBRxIoSampleResponse()
        {
        }


	    public bool containsAnalog()
        {
            return getAnalogMask() > 0;
        }


	    public bool containsDigital()
        {
            return getDigitalMaskMsb() > 0 || getDigitalMaskLsb() > 0;
        }


	    /**
	    * Returns true if the pin is enabled
	    */
	    public bool isAnalogEnabled(byte pin)
        {
            return ((getAnalogMask() >> pin) & 1) == 1;
        }


	    /**
	    * Returns true if the pin is enabled
	    */
	    public bool isDigitalEnabled(byte pin)
        {
            if (pin <= 7) {
	        	// added extra parens to calm avr compiler
		        return ((getDigitalMaskLsb() >> pin) & 1) == 1;
	        } else {
		        return ((getDigitalMaskMsb() >> (pin - 8)) & 1) == 1;
	        }
        }


	    /**
	    * Returns the 10-bit analog reading of the specified pin.
	    * Valid pins include ADC:xxx.
	    */
	    public UInt16 getAnalog(byte pin)
        {
            // analog starts 13 bytes after sample size, if no dio enabled
	        byte start = 15;

           	if (containsDigital()) {
		        // make room for digital i/o
		        start+=2;
	        }

            //	std::cout << "spacing is " << static_cast<unsigned int>(spacing) << std::endl;

        	// start depends on how many pins before this pin are enabled
	        for (byte i = 0; i < pin; i++) {
		        if (isAnalogEnabled(i)) {
			    start+=2;
		        }
            }

            return (UInt16)((getFrameData()[start] << 8) + getFrameData()[start + 1]);

        }


	    /**
	    * Returns true if the specified pin is high/on.
	    * Valid pins include DIO:xxx.
	    */
	    public bool isDigitalOn(byte pin)
        {
            if (pin <= 7) {
	        	// D0-7
		        // DIO LSB is index 5
		        return ((getFrameData()[16] >> pin) & 1) == 1;
	        } else {
		        // D10-12
        		// DIO MSB is index 4
        		return ((getFrameData()[15] >> (pin - 8)) & 1) == 1;
        	}
        }


	    public byte getDigitalMaskMsb()
        {
            return (byte)(getFrameData()[12] & 0x1c);
        }


	    public byte getDigitalMaskLsb()
        {
            return getFrameData()[13];
        }


	    public byte getAnalogMask()
        {
            return (byte)(getFrameData()[14] & 0x8f);
        }

    }   


    /**
    * Represents a Modem Status RX packet
    */
    public class ModemStatusResponse : XBeeResponse
    {
        public ModemStatusResponse()
        {
        }


	    public byte getStatus()
        {
            return getFrameData()[0];
        }
    }

       

    /**
    * Represents an AT Command RX packet
    */
    public class AtCommandResponse : FrameIdResponse 
    {
	    public AtCommandResponse()
        {
        }


		/**
		 * Returns an array containing the two character command
		 * REVISAR 
         */
		public virtual byte[] getCommand()
        {
            byte[] command = new byte[2];
            command[0] = getFrameData()[1];
            command[1] = getFrameData()[2];
            return command;
        }


		/**
		 * Returns the command status code.
		 * Zero represents a successful command
		 */
		public virtual byte getStatus()
        {
            return getFrameData()[3];
        }


		/**
		 * Returns an array containing the command value.
		 * This is only applicable to query commands.
		 * ERROR REVISAR
         */
		public virtual byte[] getValue()
        {
            byte[] value = new byte[getValueLength()];
            if (getValueLength() > 0) 
            {
                for (byte k = 0; k < getValueLength(); k++)
                {
		            // value is only included for query commands.  set commands does not return a value
		            value[k] = getFrameData()[4+k];
                    
                }
                return value;
	        }

	        return value;  //comprobar que no sea uno de los valores devueltos en caso de exito. debe identificar null
        }


		/**
		 * Returns the length of the command value array.
		 */
		public virtual byte getValueLength()
        {
            return (byte)(getFrameDataLength() - 4);
        }

        /**
		 * Returns true if status equals AT_OK
		 */
		public virtual bool isOk()
        {
            return getStatus() == AT_OK;
        }
    }


    
    /**
    * Represents a Remote AT Command RX packet
    */
    public class RemoteAtCommandResponse : AtCommandResponse
    {
	    public RemoteAtCommandResponse()
        {
        }


		/**
		 * Returns an array containing the two character command
		 */
		public override byte[] getCommand()
        {
            byte[] command = new byte[2];
            command[0] = getFrameData()[11];
            command[1] = getFrameData()[12];
            return command;
        }


		/**
		 * Returns the command status code.
		 * Zero represents a successful command
		 */
		public override byte getStatus()
        {
            return getFrameData()[13];
        }


		/**
		 * Returns an array containing the command value.
		 * This is only applicable to query commands.
		 */
		public override byte[] getValue()
        {
            
            byte[] value = new byte[getValueLength()];
            if (getValueLength() > 0) 
            {
                for (byte k = 0; k < getValueLength(); k++)
                {
		            // value is only included for query commands.  set commands does not return a value
		            value[k] = getFrameData()[14+k];
                    return value;
                }
	        }

	        return value;  //comprobar que no sea uno de los valores devueltos en caso de exito. debe identificar null
        }


		/**
		 * Returns the length of the command value array.
		 */
		public override byte getValueLength()
        {
            return (byte)(getFrameDataLength() - 14);
        }


		/**
		 * Returns the 16-bit address of the remote radio
		 */
		public UInt16 getRemoteAddress16()
        {
            return (UInt16)(((UInt16)getFrameData()[9] << 8) + getFrameData()[10]);
        }


		/**
		 * Returns the 64-bit address of the remote radio
		*/ 
		public XBeeAddress64 getRemoteAddress64()
        {
            return _remoteAddress64;
        }


        public void setRemoteAddress64(XBeeAddress64 remoteAddress64)
        {
            _remoteAddress64 = remoteAddress64;
        }


        /**
        * Returns true if command was successful
		
        public override bool isOk()
        {
            // weird c++ behavior.  w/o this method, it calls AtCommandResponse::isOk(), which calls the AtCommandResponse::getStatus, not this.getStatus!!!
            return getStatus() == AT_OK;
        }
        */


        private XBeeAddress64 _remoteAddress64;
    }




    // CLASES PARA EL ENVIO DE TRAMAS
    public class XBeeRequest : XBeeConstants
    {
        /**
	    * Constructor
	    * TODO make protected
	    */
	    public XBeeRequest(byte apiId, byte frameId)
        {
            _apiId = apiId;
	        _frameId = frameId;
        }


	    /**
	    * Sets the frame id.  Must be between 1 and 255 inclusive to get a TX status response.
	    */
	    public void setFrameId(byte frameId)
        {
            _frameId = frameId;
        }


	    /**
	    * Returns the frame id
	    */
	    public byte getFrameId()
        {
            return _frameId;
        }


	    /**
	    * Returns the API id
	    */
	    public byte getApiId()
        {
            return _apiId;
        }


	    // setting = 0 makes this a pure virtual function, meaning the subclass must implement, like abstract in java
	    /**
	    * Starting after the frame id (pos = 0) and up to but not including the checksum
	    * Note: Unlike Digi's definition of the frame data, this does not start with the API ID.
	    * The reason for this is the API ID and Frame ID are common to all requests, whereas my definition of
	    * frame data is only the API specific data.
	    */
	    public virtual byte getFrameData(byte pos)
        {
            return 0;
        }
        
	    
        
        /**
	    * Returns the size of the api frame (not including frame id or api id or checksum).
	    */
	    public virtual byte getFrameDataLength()
        {
            return 0;
        }
	
        
        //void reset();
        protected void setApiId(byte apiId)
        {
            _apiId = apiId;
        }

        
        private byte _apiId;
	    private byte _frameId;    
    
    }


    /**
    * All TX packets that support payloads extend this class
    */
    public class PayloadRequest : XBeeRequest 
    {

        public PayloadRequest(byte apiId, byte frameId, byte[] payload, byte payloadLength) : base(apiId, frameId)
        {
            _payload = payload;
            _payloadLength = payloadLength;
        }


	    /**
	    * Returns the payload of the packet, if not null
	    */
	    public byte[] getPayload()
        {
            return _payload;
        }


	    /**
	    * Sets the payload array
	    */
	    public void setPayload(byte[] payload)
        {
            _payload = payload;
        }


	    /**
	    * Returns the length of the payload array, as specified by the user.
	    */
	    public byte getPayloadLength()
        {
            return _payloadLength;
        }
        

	    /**
	    * Sets the length of the payload to include in the request.  For example if the payload array
	    * is 50 bytes and you only want the first 10 to be included in the packet, set the length to 10.
	    * Length must be <= to the array length.
	    */
	    public void setPayloadLength(byte payloadLength)
        {
            _payloadLength = payloadLength;
        }
        
        
	    private byte[] _payload;
    	private byte _payloadLength;
    }


    /**
    * Represents a Series 2 TX packet that corresponds to Api Id: ZB_TX_REQUEST
    *
    * Be careful not to send a data array larger than the max packet size of your radio.
    * This class does not perform any validation of packet size and there will be no indication
    * if the packet is too large, other than you will not get a TX Status response.
    * The datasheet says 72 bytes is the maximum for ZNet firmware and ZB Pro firmware provides
    * the ATNP command to get the max supported payload size.  This command is useful since the
    * maximum payload size varies according to certain settings, such as encryption.
    * ZB Pro firmware provides a PAYLOAD_TOO_LARGE that is returned if payload size
    * exceeds the maximum.
    */
    public class ZBTxRequest : PayloadRequest
    {
        //unsafe public ZBTxRequest(XBeeAddress64 &addr64, byte *payload, byte payloadLength){}


	    //unsafe public ZBTxRequest(XBeeAddress64 &addr64, UInt16 addr16, byte broadcastRadius, byte option, byte *payload, byte payloadLength, byte frameId){}
        
        
        
        /**
	    * Creates a default instance of this class.  At a minimum you must specify
	    * a payload, payload length and a destination address before sending this request.
	    */
	    public ZBTxRequest() : base(ZB_TX_REQUEST, DEFAULT_FRAME_ID, null, 0)
        {
        }
	    


        public ZBTxRequest(XBeeAddress64 addr64, UInt16 addr16, byte broadcastRadius, byte option, byte[] data, byte dataLength, byte frameId): base(ZB_TX_REQUEST, frameId, data, dataLength)
        {            
            _addr64 = addr64;
	        _addr16 = addr16;
	        _broadcastRadius = broadcastRadius;
	        _option = option;
        }

        //unsafe public XBeeAddress64& getAddress64(){}


        public ZBTxRequest(XBeeAddress64 addr64, byte[] data, byte dataLength) : base(ZB_TX_REQUEST, DEFAULT_FRAME_ID, data, dataLength) 
        {
            _addr64 = addr64;
	        _addr16 = ZB_BROADCAST_ADDRESS;
	        _broadcastRadius = ZB_BROADCAST_RADIUS_MAX_HOPS;
	        _option = ZB_TX_UNICAST;
        }


	    public UInt16 getAddress16()
        {
            return _addr16;
        }


	    public byte getBroadcastRadius()
        {
            return _broadcastRadius;
        }


	    public byte getOption()
        {
            return _option;
        }
        
        
        //public void setAddress64(XBeeAddress64& addr64){}


	    public void setAddress16(UInt16 addr16)
        {
            _addr16 = addr16;
        }


	    public void setBroadcastRadius(byte broadcastRadius)
        {
            _broadcastRadius = broadcastRadius;
        }


	    public void setOption(byte option)
        {
            _option = option;
        }


        // declare virtual functions
	    public override byte getFrameData(byte pos)
        {
            if (pos == 0)
            {
                return (byte)((_addr64.getMsb() >> 24) & 0xff);
            }
            else if (pos == 1)
            {
                return (byte)((_addr64.getMsb() >> 16) & 0xff);
            }
            else if (pos == 2)
            {
                return (byte)((_addr64.getMsb() >> 8) & 0xff);
            }
            else if (pos == 3)
            {
                return (byte)(_addr64.getMsb() & 0xff);
            }
            else if (pos == 4)
            {
                return (byte)((_addr64.getLsb() >> 24) & 0xff);
            }
            else if (pos == 5)
            {
                return (byte)((_addr64.getLsb() >> 16) & 0xff);
            }
            else if (pos == 6)
            {
                return (byte)((_addr64.getLsb() >> 8) & 0xff);
            }
            else if (pos == 7)
            {
                return (byte)(_addr64.getLsb() & 0xff);
            }
            else if (pos == 8)
            {
                return (byte)((_addr16 >> 8) & 0xff);
            }
            else if (pos == 9)
            {
                return (byte)(_addr16 & 0xff);
            }
            else if (pos == 10)
            {
                return (byte)(_broadcastRadius);
            }
            else if (pos == 11)
            {
                return (byte)(_option);
            }
            else
            {
                return getPayload()[pos - ZB_TX_API_LENGTH];
            }
        }

	    
        public override byte getFrameDataLength()
        {
            return (byte)(ZB_TX_API_LENGTH + getPayloadLength());
        }

        
        private XBeeAddress64 _addr64;
	    private UInt16 _addr16;
	    private byte _broadcastRadius;
	    private byte _option;
    }

    public class AtCommandRequest : XBeeRequest
    {
        public AtCommandRequest() : base(AT_COMMAND_REQUEST, DEFAULT_FRAME_ID) 
        {
            _command = null;
	        clearCommandValue();
        }

        public AtCommandRequest(byte[] command) : base(AT_COMMAND_REQUEST, DEFAULT_FRAME_ID)
        {
            _command = command;
            clearCommandValue();
        }


        public AtCommandRequest(byte[] command, byte[] commandValue, byte commandValueLength) : base(AT_COMMAND_REQUEST, DEFAULT_FRAME_ID)  
        {
            _command = command;
            _commandValue = commandValue;
            _commandValueLength = commandValueLength;
        }


	    public override byte getFrameData(byte pos)
        {
            if (pos == 0)
            {
                return _command[0];
            }
            else if (pos == 1)
            {
                return _command[1];
            }
            else
            {
                return _commandValue[pos - AT_COMMAND_API_LENGTH];
            }
        }


	    public override byte getFrameDataLength()
        {
            // command is 2 byte + length of value
            return (byte)(AT_COMMAND_API_LENGTH + _commandValueLength);
        }


	    public byte[] getCommand()
        {
            return _command;
        }


        public void setCommand(byte[] command) 
        {
            _command = command;
        }


	    public byte[] getCommandValue()
        {
            return _commandValue;
        }


	    public void setCommandValue(byte[] value)
        {
            _commandValue = value;            
        }


	    public byte getCommandValueLength()
        {
            return _commandValueLength;
        }


	    public void setCommandValueLength(byte length)
        {
            _commandValueLength = length;
        }


	    /**
	    * Clears the optional commandValue and commandValueLength so that a query may be sent
	    */
	    public void clearCommandValue()
        {
            _commandValue = null;
            _commandValueLength = 0;
        }


	    //void reset();
        private	byte[] _command = new byte[2]; 
	    private byte[] _commandValue;
	    private byte _commandValueLength;
    }

    public class RemoteAtCommandRequest : AtCommandRequest 
    {
        public RemoteAtCommandRequest() : base(null, null, 0)
        {
	        _remoteAddress16 = 0;
	        _applyChanges = false;
	        setApiId(REMOTE_AT_REQUEST);
        }


	    /**
	    * Creates a RemoteAtCommandRequest with 16-bit address to set a command.
	    * 64-bit address defaults to broadcast and applyChanges is true.
	    */
        public RemoteAtCommandRequest(UInt16 remoteAddress16, byte[] command, byte[] commandValue, byte commandValueLength) : base(command, commandValue, commandValueLength)
        {
            _remoteAddress64 = broadcastAddress64;
            _remoteAddress16 = remoteAddress16;
            _applyChanges = true;
            setApiId(REMOTE_AT_REQUEST);
        }
	    
        
        /**
	    * Creates a RemoteAtCommandRequest with 16-bit address to query a command.
	    * 64-bit address defaults to broadcast and applyChanges is true.
	    */
        public RemoteAtCommandRequest(UInt16 remoteAddress16, byte[] command) : base(command, null, 0)
        {
            _remoteAddress64 = broadcastAddress64;
	        _remoteAddress16 = remoteAddress16;
	        _applyChanges = false;
	        setApiId(REMOTE_AT_REQUEST);
        }


	    /**
	    * Creates a RemoteAtCommandRequest with 64-bit address to set a command.
        * 16-bit address defaults to broadcast and applyChanges is true.
	    */
        public RemoteAtCommandRequest(XBeeAddress64 remoteAddress64, byte[] command, byte[] commandValue, byte commandValueLength) : base(command, commandValue, commandValueLength)
        {
            _remoteAddress64 = remoteAddress64;
            // don't worry.. works for series 1 too!
            _remoteAddress16 = ZB_BROADCAST_ADDRESS;
            _applyChanges = true;
            setApiId(REMOTE_AT_REQUEST);
        } 
	    
        
        /**
	    * Creates a RemoteAtCommandRequest with 16-bit address to query a command.
	    * 16-bit address defaults to broadcast and applyChanges is true.
	    */
        public RemoteAtCommandRequest(XBeeAddress64 remoteAddress64, byte[] command) : base(command, null, 0)
        {
            _remoteAddress64 = remoteAddress64;
            _remoteAddress16 = ZB_BROADCAST_ADDRESS;
            _applyChanges = false;
            setApiId(REMOTE_AT_REQUEST);
        }

        public UInt16 getRemoteAddress16()
        {
            return _remoteAddress16;
        }


        public void setRemoteAddress16(UInt16 remoteAddress16)
        {
            _remoteAddress16 = remoteAddress16;
        }


        public XBeeAddress64 getRemoteAddress64()
        {
            return _remoteAddress64;
        }

        	    
        public void setRemoteAddress64(XBeeAddress64 remoteAddress64)
        {
            _remoteAddress64 = remoteAddress64;
        }
	    

        bool getApplyChanges()
        {
            return _applyChanges;
        }

	    
        void setApplyChanges(bool applyChanges)
        {
            _applyChanges = applyChanges;
        }

	    
        public override byte getFrameData(byte pos)
        {
            if (pos == 0)
            {
                return (byte)((_remoteAddress64.getMsb() >> 24) & 0xff);
            }
            else if (pos == 1)
            {
                return (byte)((_remoteAddress64.getMsb() >> 16) & 0xff);
            }
            else if (pos == 2)
            {
                return (byte)((_remoteAddress64.getMsb() >> 8) & 0xff);
            }
            else if (pos == 3)
            {
                return (byte)(_remoteAddress64.getMsb() & 0xff);
            }
            else if (pos == 4)
            {
                return (byte)((_remoteAddress64.getLsb() >> 24) & 0xff);
            }
            else if (pos == 5)
            {
                return (byte)((_remoteAddress64.getLsb() >> 16) & 0xff);
            }
            else if (pos == 6)
            {
                return (byte)((_remoteAddress64.getLsb() >> 8) & 0xff);
            }
            else if (pos == 7)
            {
                return (byte)(_remoteAddress64.getLsb() & 0xff);
            }
            else if (pos == 8)
            {
                return (byte)((_remoteAddress16 >> 8) & 0xff);
            }
            else if (pos == 9)
            {
                return (byte)(_remoteAddress16 & 0xff);
            }
            else if (pos == 10)
            {
                return _applyChanges ? (byte)(2) : (byte)(0);
            }
            else if (pos == 11)
            {
                return getCommand()[0];
            }
            else if (pos == 12)
            {
                return getCommand()[1];
            }
            else
            {
                return getCommandValue()[pos - REMOTE_AT_COMMAND_API_LENGTH];
            }
        }


        public override byte getFrameDataLength() 
        {
            return (byte)(REMOTE_AT_COMMAND_API_LENGTH + getCommandValueLength());
        }


        static XBeeAddress64 broadcastAddress64 = new XBeeAddress64(0x0, BROADCAST_ADDRESS);
        //	static uint16_t broadcast16Address;
        
	    private XBeeAddress64 _remoteAddress64;
	    private UInt16 _remoteAddress16;
	    private bool _applyChanges;
    
    }

}
