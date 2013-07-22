using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using System.IO.Ports;
using XBee;
using negocio; 

namespace Usuario
{
    
    public partial class TestXBee : Form
    {

        XBee.XBee XBeeA = new XBee.XBee();
        XBee.XBee XBeeB = new XBee.XBee();

        #region OTRAS_FUNC
        public XBee.XBee xbee = new XBee.XBee();
        // serial high
        public byte[] SH_Cmd = new byte[2] { (byte)'S', (byte)'H' };
        // serial low
        public byte[] SL_Cmd = new byte[2] { (byte)'S', (byte)'L' };
        // association status
        public byte[] DH_Cmd = new byte[2] { (byte)'D', (byte)'H' };
        public byte[] DL_Cmd = new byte[2] { (byte)'D', (byte)'L' };
        public byte[] AI_Cmd = new byte[2] { (byte)'A', (byte)'I' };
        public byte[] NI_Cmd = new byte[2] { (byte)'N', (byte)'I' };
        public byte[] ID_Cmd = new byte[2] { (byte)'I', (byte)'D' };
        public byte[] MY_Cmd = new byte[2] { (byte)'M', (byte)'Y' };

        public AtCommandRequest atRequest = new AtCommandRequest();
        public AtCommandResponse atResponse = new AtCommandResponse();


        public void sendAtCommand()
        {

            ComA_Mensajes.AppendText("Sending command to the XBee");
            ComA_Mensajes.AppendText(Environment.NewLine);

            // send the command
            XBeeA.send(atRequest);
            // wait up to 5 seconds for the status response
            if (XBeeA.readPacket(500))
            {
                // got a response!

                // should be an AT command response
                if (XBeeA.getResponse().getApiId() == XBee.XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeA.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        ComA_Mensajes.AppendText("Command [");
                        ComA_Mensajes.AppendText(Convert.ToString((char)atResponse.getCommand()[0]));
                        ComA_Mensajes.AppendText(Convert.ToString((char)atResponse.getCommand()[1]));
                        ComA_Mensajes.AppendText("] was successful!");
                        ComA_Mensajes.AppendText(Environment.NewLine);

                        if (atResponse.getValueLength() > 0)
                        {
                            ComA_Mensajes.AppendText("Command value length is ");
                            ComA_Mensajes.AppendText(Convert.ToString(atResponse.getValueLength()));
                            ComA_Mensajes.AppendText(Environment.NewLine);

                            ComA_Mensajes.AppendText("Command value: ");

                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                ComA_Mensajes.AppendText(String.Format("{0:X}",atResponse.getValue()[i]));
                                //ComA_Mensajes.AppendText(Convert.ToString((char)atResponse.getValue()[i]));
                                ComA_Mensajes.AppendText(" ");
                            }

                            ComA_Mensajes.AppendText(Environment.NewLine);
                        }
                    }
                    else
                    {
                        ComA_Mensajes.AppendText("Command return error code: ");
                        ComA_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(xbee.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeA.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(xbee.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }
        }

        #endregion  

        public TestXBee()
        {
            InitializeComponent();
        }

        //controla la direccion de destino 64bit en la comunicacion del modem A
        private void ComA_64Addr_mb_CheckedChanged(object sender, EventArgs e)
        {
            if(ComA_64Addr_mb.Checked)
            {
                ComA_64Addr_br.Checked = false;
            }
        }

        private void ComA_64Addr_br_CheckedChanged(object sender, EventArgs e)
        {
            if (ComA_64Addr_br.Checked)
            {
                ComA_64Addr_mb.Checked = false;
            }
        }


        //controla la direccion de destino 64bit en la comunicacion del modem B
        private void ComB_64Addr_ma_CheckedChanged(object sender, EventArgs e)
        {
            if (ComB_64Addr_ma.Checked)
            {
                ComB_64Addr_br.Checked = false;
            }
        }

        private void ComB_64Addr_br_CheckedChanged(object sender, EventArgs e)
        {
            if (ComB_64Addr_br.Checked)
            {
                ComB_64Addr_ma.Checked = false;
            }
        }


        private void ComA_16Addr_mb_CheckedChanged(object sender, EventArgs e)
        {
            if (ComA_16Addr_mb.Checked)
            {
                ComA_16Addr_br.Checked = false;
            }
        }

        private void ComA_16Addr_br_CheckedChanged(object sender, EventArgs e)
        {
            if (ComA_16Addr_br.Checked)
            {
                ComA_16Addr_mb.Checked = false;
            }
        }

        private void ComB_16Addr_ma_CheckedChanged(object sender, EventArgs e)
        {
            if (ComB_16Addr_ma.Checked)
            {
                ComB_16Addr_br.Checked = false;
            }
        }

        private void ComB_16Addr_br_CheckedChanged(object sender, EventArgs e)
        {
            if (ComB_16Addr_br.Checked)
            {
                ComB_16Addr_ma.Checked = false;
            }
        }

        
        // Al cargar el formulario añade los puertos serie disponibles en los controles de seleccion
        private void TestXBee_Load(object sender, EventArgs e)
        {
            string[] ports = SerialPort.GetPortNames();

            ComA_Selector.Items.Clear();
            ComB_Selector.Items.Clear();

            foreach (string port in ports)
            {
                ComA_Selector.Items.Add(port);
                ComB_Selector.Items.Add(port);
            }

            
            // Carga los distintos comandos AT en el selector de comandos
            ComA_ATCommand.Items.Clear(); 
            foreach (string atcomand in Enum.GetNames(typeof(XBeeConstants.Atcommands)))
            {
                ComA_ATCommand.Items.Add(atcomand);
                ComB_ATCommand.Items.Add(atcomand);
            }

            // Borra cualquier dato de los distintos cuadros de salida
            ComA_SHaddr.Text = "";
            ComA_SLaddr.Text = "";
            ComA_16Addr.Text = "";
            ComA_64Addr.Text = "";

            ComB_SHaddr.Text = "";
            ComB_SLaddr.Text = "";
            ComB_16Addr.Text = "";
            ComB_64Addr.Text = "";

            ComA_TipoTrama.Items.Clear();
            ComB_TipoTrama.Items.Clear();
            foreach (string tipos in Enum.GetNames(typeof(XBeeConstants.RequestApiFrames)))
            {
                ComA_TipoTrama.Items.Add(tipos);
                ComB_TipoTrama.Items.Add(tipos);
            }
        }


        private void TestXBee_FormClosing(Object sender, FormClosingEventArgs e)
        {
            XBeeA.close();
            XBeeB.close();
        }


        private void PuertoASelector_SelectedIndexChanged(object sender, EventArgs e)
        {
            
        }

        private void ComA_Leer_Click(object sender, EventArgs e)
        {
            XBeeA.begin(ComA_Selector.Text,9600);

            string dato;

            atRequest.setCommand(SH_Cmd);
            XBeeA.send(atRequest);
            if (XBeeA.readPacket(500))
            {
                if (XBeeA.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeA.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";            
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComA_SHaddr.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComA_Mensajes.AppendText("Command return error code: ");
                        ComA_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeA.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeA.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeA.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }
            
                     
            
            atRequest.setCommand(SL_Cmd);
            XBeeA.send(atRequest);
            if (XBeeA.readPacket(500))
            {
                if (XBeeA.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeA.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComA_SLaddr.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComA_Mensajes.AppendText("Command return error code: ");
                        ComA_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeA.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeA.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeA.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }
            
            atRequest.setCommand(DH_Cmd);
            XBeeA.send(atRequest);
            if (XBeeA.readPacket(500))
            {
                if (XBeeA.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeA.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComA_DHaddr.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComA_Mensajes.AppendText("Command return error code: ");
                        ComA_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeA.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeA.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeA.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }
            

            atRequest.setCommand(DL_Cmd);
            XBeeA.send(atRequest);
            if (XBeeA.readPacket(500))
            {
                if (XBeeA.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeA.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComA_DLaddr.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComA_Mensajes.AppendText("Command return error code: ");
                        ComA_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeA.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeA.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeA.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }
            

            atRequest.setCommand(ID_Cmd);
            XBeeA.send(atRequest);
            if (XBeeA.readPacket(500))
            {
                if (XBeeA.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeA.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComA_ID.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComA_Mensajes.AppendText("Command return error code: ");
                        ComA_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeA.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeA.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeA.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }
            

            atRequest.setCommand(MY_Cmd);
            XBeeA.send(atRequest);
            if (XBeeA.readPacket(500))
            {
                if (XBeeA.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeA.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComA_MY.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComA_Mensajes.AppendText("Command return error code: ");
                        ComA_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeA.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeA.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeA.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }
            

        }

        private void ComA_Enviar_Click(object sender, EventArgs e)
        {
            byte[] commandoAT = new byte[2];
            string dato;

            switch (ComA_TipoTrama.Text) 
            {
                case "AtCommandReq":
                    ComA_Mensajes.AppendText("Pulsado AtCommand Request" + Environment.NewLine);
                    ComA_Mensajes.AppendText("      Enviando comando : " + ComA_ATCommand.Text + Environment.NewLine);
                    char[] temp = ComA_ATCommand.Text.ToCharArray();
                    for (int k = 0; k < temp.Length; k++)
                    {
                        commandoAT[k] = (byte)temp[k];
                    }

                    atRequest.setCommand(commandoAT);
                    XBeeA.send(atRequest);
                    if (XBeeA.readPacket(500))
                    {
                        if (XBeeA.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                        {
                            XBeeA.getResponse().getAtCommandResponse(ref atResponse);

                            if (atResponse.isOk())
                            {
                                if (atResponse.getValueLength() > 0)
                                {
                                    dato = "";
                                    for (int i = 0; i < atResponse.getValueLength(); i++)
                                    {
                                        dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                    }
                                    ComA_Mensajes.AppendText("Resultado del comando : " + dato + Environment.NewLine);
                                }
                            }
                            else
                            {
                                ComA_Mensajes.AppendText("Command return error code: ");
                                ComA_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                            }
                        }
                        else
                        {
                            Console.Write("Expected AT response but got ");
                            Console.Write(XBeeA.getResponse().getApiId());
                        }
                    }
                    else
                    {
                        // at command failed
                        if (XBeeA.getResponse().isError())
                        {
                            Console.Write("Error reading packet.  Error code: ");
                            Console.WriteLine(XBeeA.getResponse().getErrorCode());
                        }
                        else
                        {
                            Console.Write("No response from radio");
                        }
                    }
                    break;

                case "RemoteAtCommandReq":
                    ComA_Mensajes.AppendText("Pulsado Remote AtCommand Request");
                    ComA_Mensajes.AppendText(Environment.NewLine);
                    break;

                case "ZBTransmitReq":
                    ComA_Mensajes.AppendText("Pulsado ZigBee Data Request");
                    ComA_Mensajes.AppendText(Environment.NewLine);
                    break;

                default:
                    break;
            }
        }

        private void ComB_Leer_Click(object sender, EventArgs e)
        {
            XBeeB.begin(ComB_Selector.Text, 9600);

            string dato;

            atRequest.setCommand(SH_Cmd);
            XBeeB.send(atRequest);
            if (XBeeB.readPacket(500))
            {
                if (XBeeB.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeB.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComB_SHaddr.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComB_Mensajes.AppendText("Command return error code: ");
                        ComB_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeB.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeB.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeB.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }



            atRequest.setCommand(SL_Cmd);
            XBeeB.send(atRequest);
            if (XBeeB.readPacket(500))
            {
                if (XBeeB.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeB.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComB_SLaddr.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComB_Mensajes.AppendText("Command return error code: ");
                        ComB_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeB.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeB.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeB.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }

            atRequest.setCommand(DH_Cmd);
            XBeeB.send(atRequest);
            if (XBeeB.readPacket(500))
            {
                if (XBeeB.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeB.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComB_DHaddr.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComB_Mensajes.AppendText("Command return error code: ");
                        ComB_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeB.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeB.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeB.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }


            atRequest.setCommand(DL_Cmd);
            XBeeB.send(atRequest);
            if (XBeeB.readPacket(500))
            {
                if (XBeeB.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeB.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComB_DLaddr.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComB_Mensajes.AppendText("Command return error code: ");
                        ComB_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeB.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeB.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeB.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }


            atRequest.setCommand(ID_Cmd);
            XBeeB.send(atRequest);
            if (XBeeB.readPacket(500))
            {
                if (XBeeB.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeB.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComB_ID.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComB_Mensajes.AppendText("Command return error code: ");
                        ComB_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeB.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeB.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeB.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }


            atRequest.setCommand(MY_Cmd);
            XBeeB.send(atRequest);
            if (XBeeB.readPacket(500))
            {
                if (XBeeB.getResponse().getApiId() == XBeeConstants.AT_COMMAND_RESPONSE)
                {
                    XBeeB.getResponse().getAtCommandResponse(ref atResponse);

                    if (atResponse.isOk())
                    {
                        if (atResponse.getValueLength() > 0)
                        {
                            dato = "";
                            for (int i = 0; i < atResponse.getValueLength(); i++)
                            {
                                dato = string.Concat(dato, string.Format("{0:X2}", atResponse.getValue()[i]));
                                ComB_MY.Text = dato;
                            }

                        }
                    }
                    else
                    {
                        ComB_Mensajes.AppendText("Command return error code: ");
                        ComB_Mensajes.AppendText(Convert.ToString(atResponse.getStatus()));
                    }
                }
                else
                {
                    Console.Write("Expected AT response but got ");
                    Console.Write(XBeeB.getResponse().getApiId());
                }
            }
            else
            {
                // at command failed
                if (XBeeB.getResponse().isError())
                {
                    Console.Write("Error reading packet.  Error code: ");
                    Console.WriteLine(XBeeB.getResponse().getErrorCode());
                }
                else
                {
                    Console.Write("No response from radio");
                }
            }

        }

    }
}
