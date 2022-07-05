table 80024 "PC EDI Header Buffer"
{
    fields
    {
        Field(10;ID;integer)
        {
            AutoIncrement = true;
        }
        field(20;"Response Type"; option)
        {
            OptionMembers = ,Response,Dispatch,Invoice,CreditNote,Inventory;
        }
        field(30;"Purchase Order No."; Code[20])
        {
        }
        field(40;"Date Received"; date)
        {
        }
        field(50;"Supplier No."; Code[20])
        {
        }
        field(60;Data;Blob)
        {
        }
        field(70;Processed;boolean)
        {
        }
    }
    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
    }
    trigger OnDelete()
    var
        EDI:record "PC EDI Line Buffer";
    begin
        EDI.reset;
        EDI.Setrange(ID,ID);
        If EDI.findset then EDI.DeleteAll();
    end;
}