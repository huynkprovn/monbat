using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace XBee
{
    public class XBeeConstants
    {
        #region DECLARACION_DE_CONSTANTES
        // set to ATAP value of XBee. AP=2 is recommended
        public const byte ATAP = 2;
        public const byte START_BYTE = 0x7e;
        public const byte ESCAPE = 0x7d;
        public const byte XON = 0x11;
        public const byte XOFF = 0x13;

        // This value determines the size of the byte array for receiving RX packets
        // Most users won't be dealing with packets this large so you can adjust this
        // value to reduce memory consumption. But, remember that
        // if a RX packet exceeds this size, it cannot be parsed!

        // This value is determined by the largest packet size (100 byte payload + 64-bit address + option byte and rssi byte) of a series 1 radio
        public const UInt16 MAX_FRAME_DATA_SIZE = 110;

        public const UInt16 BROADCAST_ADDRESS = 0xffff;
        public const UInt16 ZB_BROADCAST_ADDRESS = 0xfffe;

        // the non-variable length of the frame data (not including frame id or api id or variable data size (e.g. payload, at command set value)
        public const byte ZB_TX_API_LENGTH = 12;
        public const byte TX_16_API_LENGTH = 3;
        public const byte TX_64_API_LENGTH = 9;
        public const byte AT_COMMAND_API_LENGTH = 2;
        public const byte REMOTE_AT_COMMAND_API_LENGTH = 13;
        // start/length(2)/api/frameid/checksum bytes
        public const byte PACKET_OVERHEAD_LENGTH = 6;
        // api is always the third byte in packet
        public const byte API_ID_INDEX = 3;

        // frame position of rssi byte
        public const byte RX_16_RSSI_OFFSET = 2;
        public const byte RX_64_RSSI_OFFSET = 8;

        public const byte DEFAULT_FRAME_ID = 1;
        public const byte NO_RESPONSE_FRAME_ID = 0;

        // TODO put in tx16 class
        public const byte ACK_OPTION = 0;
        public const byte DISABLE_ACK_OPTION = 1;
        public const byte BROADCAST_OPTION = 4;

        // RX options
        public const byte ZB_PACKET_ACKNOWLEDGED = 0x01;
        public const byte ZB_BROADCAST_PACKET = 0x02;

        // not everything is implemented!
        /**
         * Api Id constants
         */
        public const byte TX_64_REQUEST = 0x0;
        public const byte TX_16_REQUEST = 0x1;
        public const byte AT_COMMAND_REQUEST = 0x08;
        public const byte AT_COMMAND_QUEUE_REQUEST = 0x09;
        public const byte REMOTE_AT_REQUEST = 0x17;
        public const byte ZB_TX_REQUEST = 0x10;
        public const byte ZB_EXPLICIT_TX_REQUEST = 0x11;
        public const byte RX_64_RESPONSE = 0x80;
        public const byte RX_16_RESPONSE = 0x81;
        public const byte RX_64_IO_RESPONSE = 0x82;
        public const byte RX_16_IO_RESPONSE = 0x83;
        public const byte AT_RESPONSE = 0x88;
        public const byte TX_STATUS_RESPONSE = 0x89;
        public const byte MODEM_STATUS_RESPONSE = 0x8a;
        public const byte ZB_RX_RESPONSE = 0x90;
        public const byte ZB_EXPLICIT_RX_RESPONSE = 0x91;
        public const byte ZB_TX_STATUS_RESPONSE = 0x8b;
        public const byte ZB_IO_SAMPLE_RESPONSE = 0x92;
        public const byte ZB_IO_NODE_IDENTIFIER_RESPONSE = 0x95;
        public const byte AT_COMMAND_RESPONSE = 0x88;
        public const byte REMOTE_AT_COMMAND_RESPONSE = 0x97;


        /**
         * TX STATUS constants
         */
        public const byte SUCCESS = 0x0;
        public const byte CCA_FAILURE = 0x2;
        public const byte INVALID_DESTINATION_ENDPOINT_SUCCESS = 0x15;
        public const byte NETWORK_ACK_FAILURE = 0x21;
        public const byte NOT_JOINED_TO_NETWORK = 0x22;
        public const byte SELF_ADDRESSED = 0x23;
        public const byte ADDRESS_NOT_FOUND = 0x24;
        public const byte ROUTE_NOT_FOUND = 0x25;
        public const byte PAYLOAD_TOO_LARGE = 0x74;

        // modem status
        public const byte HARDWARE_RESET = 0;
        public const byte WATCHDOG_TIMER_RESET = 1;
        public const byte ASSOCIATED = 2;
        public const byte DISASSOCIATED = 3;
        public const byte SYNCHRONIZATION_LOST = 4;
        public const byte COORDINATOR_REALIGNMENT = 5;
        public const byte COORDINATOR_STARTED = 6;

        public const byte ZB_BROADCAST_RADIUS_MAX_HOPS = 0;

        public const byte ZB_TX_UNICAST = 0;
        public const byte ZB_TX_BROADCAST = 8;

        public const byte AT_OK = 0;
        public const byte AT_ERROR = 1;
        public const byte AT_INVALID_COMMAND = 2;
        public const byte AT_INVALID_PARAMETER = 3;
        public const byte AT_NO_RESPONSE = 4;

        public const byte NO_ERROR = 0;
        public const byte CHECKSUM_FAILURE = 1;
        public const byte PACKET_EXCEEDS_BYTE_ARRAY_LENGTH = 2;
        public const byte UNEXPECTED_START_BYTE = 3;

        public enum Atcommands :byte {DH , DL, MY, MP, NC, SH, SL, NI, SE, DE, CI, NP, DD, CH, DA, ID, OP, NH, BH, OI, NT, NO, SC, SD, ZS, NJ, JV, NW, JN, AR, DJ, II, EE, EO, NK, KY, PL, PM, DB, PP, AP, AO, BD, NB, SB, RO, D7, D6, IR, IC, P0, P1, P2, P3, D0, D1, D2, D3, D4, D5, D8, LT, PR, RP, _V, V_, TP, VR, HV, AI, CT, CN, GT, CC, SM, SN, SP, ST, SO, WH, SI, PO, AC, WR, RE, FR, NR, CB, ND, DN, IS, _S };
        public enum RequestApiFrames : byte {AtCommandReq, RemoteAtCommandReq, ZBTransmitReq};
        #endregion
    }
}
