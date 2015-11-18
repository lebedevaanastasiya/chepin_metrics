using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Text.RegularExpressions;
using System.IO;


namespace msis_lab1
{

    class Program
    {  
        static string pattern;
        static Regex regex;
        static Match match;
        static string raw_text_of_program = "";  
        static string bodies_text = "";
        static string[] array_of_variables = { };
        static int 
            permanent_variables,   //немодифицируемые                   
            modifiable_variables,  //модифицируемые                   
            control_variables,     //управляющие                   
            tangle_variables;      //неисползуемые
        static double chepin_number;        //число Чепина

        static void Main(string[] args)
        {
            string is_program_continuation = "1";
            string path_of_program_foulder = @"..\";
            string path_of_program_file = @"..\";    
            string regular_expression_for_variables = @"(var(\s*([a-zA-Z_]{1}\w*\s*,?\s*)+\s*:\s*((([a-zA-Z_]{1}\w*){1})|(array([\[\]0-9,\s'(..)]*)?\s+(of){1}\s+([a-zA-Z_]{1}\w*){1})|(\([,\sa-zA-Z_0-9]*\))|(set\s+of\s+[\(\)0-9'a-zA-Z(..),\s]*))\s*;\s*)+){1}",
                   regular_expression_for_programs_body = @"(\bbegin\b){1}";

            Console.WriteLine("\nWhat do you want to do?\n\n1 - > Evaluation of the program by using Chapin\'s metric\n0 - > Exit");
            is_program_continuation = Console.ReadLine();
            while (is_program_continuation =="1")
            {
                permanent_variables = 0;  
                modifiable_variables = 0; 
                control_variables = 0;     
                tangle_variables = 0;      
                chepin_number = 0;
   
                Console.WriteLine("Enter the name of file:");
                path_of_program_file = path_of_program_foulder + @Console.ReadLine();
                Console.WriteLine("\n-----------------------------------------------------------------------\n");
                try
                {
                    raw_text_of_program = ReadProgramText(path_of_program_file);
                    Console.WriteLine(raw_text_of_program);
                    Console.WriteLine("\n-----------------------------------------------------------------------\n");
                    raw_text_of_program = DeleteCommentsAndStrings(raw_text_of_program);
                    Console.WriteLine(raw_text_of_program);

                    if (SearchOutCoincidence(regular_expression_for_variables, "", "", raw_text_of_program))
                        raw_text_of_program = regex.Replace(raw_text_of_program, "");
                    MakeArrayOfVariables();
                    if (SearchOutCoincidence(regular_expression_for_programs_body, "", "", raw_text_of_program))
                        bodies_text = raw_text_of_program.Substring(match.Index, raw_text_of_program.Length - match.Index);
                    MakeChapinsNumber();

                    Console.WriteLine("\n-----------------------------------------------------------------------\n");
                    Console.WriteLine("Number of modifiable variables:  М = {0}", modifiable_variables);
                    Console.WriteLine("Number of permanent variables:   P = {0}", permanent_variables);
                    Console.WriteLine("Number of control variables:     C = {0}", control_variables);
                    Console.WriteLine("Number of tangle variables:      T = {0}", tangle_variables);
                    Console.WriteLine("\nChepin Number:  Q = {0}", chepin_number);
                    Console.WriteLine("\n-----------------------------------------------------------------------\n");
                    
                }
                catch (Exception e)
                {
                    Console.WriteLine("\nFile is not found! Try again!\n");
                }
                Console.WriteLine("What do you want to do?\n1 - > Evaluation of the program by using Chapin\'s metric\n0 - > Exit");
                is_program_continuation = Console.ReadLine();
            }
            Console.WriteLine("Bye! :)");
            Console.ReadLine();
        }

        static  bool SearchOutCoincidence(string regular_expressions_start,string variables_name,string regular_expressions_finish,string text_for_search)
        {
            string temp_string = "";

            temp_string = regular_expressions_start + variables_name + regular_expressions_finish;
            pattern = temp_string;
            regex = new Regex(pattern, RegexOptions.IgnoreCase);
            match = regex.Match(text_for_search);
            return match.Success;
        }

        static string DeleteCommentsAndStrings(string text)
        {
            int state;
            const int 
                in_comment_of_1st_type = 1,
                in_comment_of_2nd_type = 2,
                in_comment_of_3rd_type = 3,
                in_string = 4,
                in_program = 0;
            const int 
                length_of_1st_type_comment_left_border = 2,
                length_of_3rd_type_comment_border = 2;
            int comments_start, comments_finish;

            state = in_program;
            int i = 0;
            while (i < text.Length - 1)
            {
                comments_start = 0;
                comments_finish = 0;
                if (text[i] == '/' && text.IndexOf("//") == i)
                    state = in_comment_of_1st_type;
                if (text[i] == '{')
                    state = in_comment_of_2nd_type;
                if (text[i] == '(' && text.IndexOf("(*") == i)
                    state = in_comment_of_3rd_type;
                if (text[i] == '\'')
                    state = in_string;

                switch (state)
                {   
                    case in_comment_of_1st_type:
                        comments_start = i;
                        for (int k = comments_start + length_of_1st_type_comment_left_border; (k < text.Length) && comments_finish == 0; k++)
                            if (text[k] == '\n')
                                comments_finish = k;
                        text = text.Remove(comments_start, comments_finish - comments_start);
                        state = in_program;
                        break;
                    case in_comment_of_2nd_type:
                        comments_start = i;
                        for (int k = comments_start + 1; (k < text.Length) && comments_finish == 0; k++)
                            if (text[k] == '}')
                                comments_finish = k;
                        text = text.Remove(comments_start, comments_finish - comments_start + 1);
                        state = in_program;
                        break;
                    case in_comment_of_3rd_type:
                        comments_start = i;
                        for (int k = comments_start + length_of_3rd_type_comment_border; (k < text.Length - 1) && comments_finish == 0; k++)
                            if (text[k] == '*' && text[k + 1] == ')')
                                comments_finish = k;
                        text = text.Remove(comments_start, comments_finish - comments_start + length_of_3rd_type_comment_border);
                        state = in_program;
                        break;
                    case in_string:
                        i++;
                        while (text[i] != '\'')
                        {
                            text = text.Remove(i, 1);
                        }
                        i++;
                        state = in_program;
                        break;
                    case in_program: i++;
                        break;
                }
            }
            return text;
        }

        static void MakeArrayOfVariables()
        {
            string varblocks_text = "",
                   temp_variable = "";
            int size_of_array = 0;            
    
            while (match.Success)
            {
                varblocks_text = varblocks_text + "\n" + match.Groups[0].Value;
                match = match.NextMatch();
            }
            int i = -1;
            while (i < varblocks_text.Length - 1)
            {
                i++;
                for (; (varblocks_text[i] != ',' && varblocks_text[i] != ':' &&
                     varblocks_text[i] != ' ' && varblocks_text[i] != '\n' &&
                     varblocks_text[i] != '\r' && varblocks_text[i] != ';' &&
                     varblocks_text[i] != '\t') &&
                     (i < varblocks_text.Length); i++)
                {
                    temp_variable += varblocks_text[i];
                }
                if (varblocks_text[i] == ':')
                {
                    for (; (i < varblocks_text.Length - 1) && (varblocks_text[i] != ';'); i++) ;
                }
                if ((temp_variable != "") && (temp_variable != "var"))
                {
                    size_of_array++;
                    Array.Resize(ref array_of_variables, size_of_array);
                    array_of_variables[array_of_variables.Length - 1] = temp_variable;
                    temp_variable = "";
                }
                if (temp_variable == "var")
                    temp_variable = "";
            } 

        }

        static void MakeChapinsNumber()
        {
            const int 
                modifiable_coefficient = 2,
                permanent_coefficient = 1,
                control_coefficient = 3;
            const double
                tangle_coefficient = 0.5;
            const string
                left_border_of_word = @"(\b",
                right_border_of_word = @"\b){1}",
                left_border_of_assignment = @"(\b",
                right_border_of_assignment = @"\b\s*:=){1}",
                left_border_of_until = @"(\buntil\b([^;]|[\s])*\b",
                right_border_of_until = @"\b([^;]|[\s]|[\w])*;){1}",
                left_border_of_while = @"(\bwhile\b[(not)\s()\w><=':+*\-\/]*\b",
                right_border_of_while = @"\b[(not)\s()\w><=':+\-*\/]*\bdo\b){1}",
                left_border_of_case = @"(\bcase\b[\s()\w><=':+*\-\/]*\b",
                right_border_of_case = @"\b[\s()\w><=':+*\-\/]*\bof\b){1}",
                left_border_of_if = @"(\bif\b[(not)\s()\w><='+*\-\/]*\b",
                right_border_of_if = @"\b[(not)\s()\w><='+*\-\/]*\bthen\b){1}",
                left_border_of_for = @"(\bfor\b[\s()\w><=':+*\-\/]*\b",
                right_border_of_for = @"\b[\s()\w><=':+*\-\/]*\bdo\b){1}";

            for (int j = 0; j < array_of_variables.Length; j++)
            {               
                if (SearchOutCoincidence(left_border_of_word, 
                                         array_of_variables[j], 
                                         right_border_of_word, bodies_text)) //is_in_program
                {
                    if (SearchOutCoincidence(left_border_of_assignment, 
                                             array_of_variables[j], 
                                             right_border_of_assignment, bodies_text)) //is_in_':='
                        modifiable_variables++;
                    else
                        permanent_variables++;
                    if (SearchOutCoincidence(left_border_of_until, 
                                             array_of_variables[j],
                                             right_border_of_until, bodies_text))  //is_in_'UNTIL'    
                        control_variables++;
                    else
                        if (SearchOutCoincidence(left_border_of_while,
                                                 array_of_variables[j],
                                                 right_border_of_while, bodies_text)) //is_in_'WHILE' 
                            control_variables++;
                        else
                            if (SearchOutCoincidence(left_border_of_case,
                                                     array_of_variables[j], 
                                                     right_border_of_case, bodies_text)) //is_in_'CASE'
                                control_variables++;
                            else
                                if (SearchOutCoincidence(left_border_of_if, 
                                                         array_of_variables[j], 
                                                         right_border_of_if, bodies_text))//is_in_'IF'
                                    control_variables++;
                                else
                                    if (SearchOutCoincidence(left_border_of_for,
                                                             array_of_variables[j], 
                                                             right_border_of_for, bodies_text))  //is_in_'FOR'
                                        control_variables++;
                }
                else
                    tangle_variables++; //is_unused
            }
            chepin_number = permanent_coefficient*permanent_variables 
                            + modifiable_coefficient* modifiable_variables 
                            + control_coefficient * control_variables 
                            + tangle_coefficient * tangle_variables;
        }
        static string ReadProgramText(string path_of_program_file)
        {
            string program_text;
            StreamReader file = File.OpenText(path_of_program_file);
            program_text = file.ReadToEnd();
            file.Close();
            return program_text;
        }
    }
}
