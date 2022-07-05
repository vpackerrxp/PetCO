table 80016 "PC Execution Log"
{
  
    fields
    {
        field(10;ID; Integer)
        {
            AutoIncrement = true;       
        }
        field(15;"Execution Start Time"; Datetime)
        {
        }
        field(20;"Execution Time"; Datetime)
        {
        }
        field(30;Operation; text[80])
        {
        }
        field(50;"Error Message"; text[250])
        {
        }
        field(40;Status; Option)
        {
            OptionMembers = Fail,Pass;
        }
    }
    
    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }
    
}