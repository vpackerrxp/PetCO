table 80019 "PC Shopify Update Log"
{
  
    fields
    {
        field(10;"ID"; Integer)
        {
            AutoIncrement = True;
        }
        field(20;"Error Date/Time"; Datetime)
        {
            Editable = false;
        }
        field(30;"Error Condition";Text[250])
        {
            Editable = false;
        }
        field(40;"Web Service Error";text[2048])
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
    /*procedure Get_Web_Service_Error() ReturnValue: text
    var
        InStr: InStream;
        Line: text;
    begin
        if not Rec."Web Service Error".HasValue then
            exit;

        rec."Web Service Error".CreateInStream(InStr);
        InStr.ReadText(ReturnValue);

        while not InStr.EOS do begin
            InStr.ReadText(Line);
            ReturnValue += Line;
        end;
    end;*/
}