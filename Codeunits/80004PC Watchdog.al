codeunit 80004 "PC Watchdog"
{
    trigger OnRun()
    begin
        WatchDog();
    end;
    procedure WatchDog():Boolean
    var
        Jobq:record "Job Queue Entry";
        Jqlog:record "Job Queue Log Entry";
        CU:Codeunit "PC Shopify Routines";
    begin
        Jobq.reset;
        Jobq.setrange("Object Type to Run",Jobq."Object Type to Run"::Codeunit);
        Jobq.Setrange("Object ID to Run",Codeunit::"PC Shopify Routines");
       // Jobq.Setrange("Object ID to Run",Codeunit::test);
        Jobq.Setrange(Status,Jobq.Status::Error);
        If Jobq.findSet then
        begin
            Jqlog.Reset();
            Jqlog.Setrange("Object Type to Run",Jobq."Object Type to Run");
            Jqlog.Setrange("Object ID to Run",Jobq."Object ID to Run");
            If Jqlog.Findlast() then
            begin
                CU.Send_Email_Msg('PC Shopify Job Queue Error',jQlog."Error Message",'vpacker@practiva.com.au');
                CU.Send_Email_Msg('PC Shopify Job Queue Error',jQlog."Error Message",'operations@petculture.com.au');
                Jobq.Restart();
            end;
        end;
        Jobq.Setrange("Object ID to Run",Codeunit::"PC EDI Routines");
        If Jobq.findSet then
        begin
            Jqlog.Reset();
            Jqlog.Setrange("Object Type to Run",Jobq."Object Type to Run");
            Jqlog.Setrange("Object ID to Run",Jobq."Object ID to Run");
            If Jqlog.Findlast() then
            begin
                CU.Send_Email_Msg('PC EDI Job Queue Error',jQlog."Error Message",'vpacker@practiva.com.au');
                CU.Send_Email_Msg('PC EDI Job Queue Error',jQlog."Error Message",'operations@petculture.com.au');
                Jobq.Restart();
            end;
        end;
    end;
}
