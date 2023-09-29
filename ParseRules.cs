using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;




public class ParseRules
{
    public static void Main(string[] args)
    {
        if(args.Length<3)
        {
            Console.WriteLine("Specify the network interface name and configfilepath\n usage ParseRules {interfacename} {configfilepath} {sysctl.conf}");
            return;
        }
        string interfacename = args[0];
        string configPath = args[1];
        string sysctlPath = args[2];
        
        if(File.Exists(configPath))
        {
            string[] allines = File.ReadAllLines(configPath);
            string[] natlines = {
                "*nat",
                String.Format("-A POSTROUTING -s 10.10.10.0/24 -o {0} -m policy --pol ipsec --dir out -j ACCEPT",interfacename),
                String.Format("-A POSTROUTING -s 10.10.10.0/24 -o {0} -j MASQUERADE",interfacename),
                "COMMIT",
                "",
                "*mangle",
                String.Format("-A FORWARD --match policy --pol ipsec --dir in -s 10.10.10.0/24 -o {0} -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360",interfacename),
                "COMMIT",
                
            };
            string[] filterlines = {
                "-A ufw-before-forward --match policy --pol ipsec --dir in --proto esp -s 10.10.10.0/24 -j ACCEPT",
                "-A ufw-before-forward --match policy --pol ipsec --dir out --proto esp -d 10.10.10.0/24 -j ACCEPT"
            };
            List<String> al = new List<String>(allines);
            int line_index = 0;
            for(line_index=0;line_index<al.Count;)
            {
                string line = al[line_index];
                if(line=="*filter")
                {
                    
                    --line_index;
                    line = al[line_index];
                    while(line_index>0 && line.StartsWith("#")){
                        --line_index;
                        line = al[line_index];
                    }
                        
                    if(line_index<0)
                        line_index = 0;
                    
                    al.InsertRange(line_index,natlines);
                    break;
                }
                else
                {
                    ++line_index;
                }
            }
            
            for(line_index=0;line_index<al.Count;)
            {
                string line = al[line_index];
                if(line=="*filter")
                {
                    while((!line.StartsWith("#"))&&line!="")
                    {
                        ++line_index;
                        line = al[line_index];
                    }
                    al.InsertRange(line_index,filterlines);
                    break;
                }
                else
                {
                    ++line_index;
                }
            }
            
            File.WriteAllLines(configPath,al);
        }
        if(File.Exists(sysctlPath))
        {
            string[] allines = File.ReadAllLines(sysctlPath);
            List<String> al = new List<String>(allines);
            List<String> toInsert = new List<String>();
            string[] linesToFind = {"net/ipv4/ip_forward=1","net/ipv4/conf/all/accept_redirects=0","net/ipv4/conf/all/send_redirects=0","net/ipv4/ip_no_pmtu_disc=1"};
            foreach(string line in linesToFind)
            {
                if(!al.Contains(line))
                {
                    toInsert.Add(line);
                }
            }
            al.AddRange(toInsert);
            File.WriteAllLines(sysctlPath,al);
        }
    }
}

