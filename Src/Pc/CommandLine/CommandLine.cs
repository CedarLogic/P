﻿using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Microsoft.Pc
{
    public class CommandLine
    {
        private static int Main(string[] args)
        {
            CommandLineOptions options;
            if (!CommandLineOptions.ParseCompileString(args, out options))
            {
                goto error;
            }
            bool result;
            if (options.compilerService)
            {
                // use separate process that contains pre-compiled P compiler.
                CompilerServiceClient svc = new CompilerServiceClient();
                if (string.IsNullOrEmpty(options.outputDir))
                {
                    options.outputDir = Directory.GetCurrentDirectory();
                }
                result = svc.Compile(options, Console.Out);
            }
            else
            {
                var compiler = new Compiler(options.shortFileNames);
                result = compiler.Compile(new StandardOutput(), options);
            }
            if (!result)
            {
                return -1;
            }
            return 0;

            error:
            {
                Console.WriteLine("USAGE: Pc.exe file.p [options]");
                Console.WriteLine("Compiles *.p programs and produces *.4ml intermediate output which can then be passed to PLink.exe");
                Console.WriteLine("/outputDir:path         -- where to write the linker.c and linker.h files");
                Console.WriteLine("/liveness[:mace]        -- these control what the Zing program is looking for");
                Console.WriteLine("/shortFileNames         -- print only file names in error messages");
                Console.WriteLine("/printTypeInference     -- dumps compiler type inference information (in formula)");
                Console.WriteLine("/dumpFormulaModel       -- write the entire formula model to a file named 'output.4ml'");
                Console.WriteLine("/profile                -- print detailed timing information)");
                Console.WriteLine("/generate:[C0,C,Zing,C#]");
                Console.WriteLine("    C0  : generate C without model functions");
                Console.WriteLine("    C   : generate C with model functions");
                Console.WriteLine("    Zing: generate Zing");
                Console.WriteLine("    C#  : generate C# code");
                Console.WriteLine("/shared                 -- use the compiler service)"   );
                return -1;
            }
        }
    }
}