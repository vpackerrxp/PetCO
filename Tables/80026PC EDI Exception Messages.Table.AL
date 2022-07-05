table 80026 "PC EDI Exception Messages"
{
    DataClassification = ToBeClassified;
    fields
    {
        field(10;ID; Integer)
        {
            AutoIncrement = true;
        }
        field(15;"Exception Date";Date)
        {
            Editable = false;
        }
       field(20;"Purchase Order No.";Code[20])
        {
            Editable = false;
        }
        field(30;"Exception Message"; Text[350])
        {
            Editable = false;
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
         