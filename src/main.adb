with Ada.Text_IO; use Ada.Text_IO;

procedure main is
   NumElements : constant := 100000;
   NumThreads  : constant := 16;
   type my_array is array (1 .. NumElements) of Long_Long_Integer;

   a : my_array;

   function part_sum (left : Integer; Right : Integer) return Long_Long_Integer
   is
      sum : Long_Long_Integer := 0;
      i   : Integer;
   begin
      i := left;
      while i <= Right loop
         sum := sum + a (i);
         i   := i + 1;
      end loop;
      return sum;
   end part_sum;

   procedure create_array is
   begin
      for i in a'Range loop
         a (i) := Long_Long_Integer (i);
      end loop;
   end create_array;

   protected task_manager is
      procedure set_res (sum : in Long_Long_Integer);
      entry get_res (sum : out Long_Long_Integer);
   private
      sum          : Long_Long_Integer := 0;
      task_counter : Integer      := 0;
   end task_manager;

   protected body task_manager is
      procedure set_res (sum : in Long_Long_Integer) is
      begin
         task_manager.sum := task_manager.sum + sum;
         task_counter := task_counter + 1;
      end set_res;

      entry get_res (sum : out Long_Long_Integer) when task_counter = NumThreads is
      begin
         sum := task_manager.sum;
      end get_res;

   end task_manager;

   task type my_task is
      entry start (left, Right : in Integer);
   end my_task;

   task body my_task is
      left, Right : Integer;
      sum         : Long_Long_Integer := 0;
   begin
      accept start (left, RigHt : in Integer) do
         my_task.left  := left;
         my_task.right := Right;
      end start;

      sum := part_sum (left, Right);
      task_manager.set_res (sum);
   end my_task;

   tasks : array (1 .. NumThreads) of my_task;

   sum_singlethread     : Long_Long_Integer;
   sum_multithread : Long_Long_Integer;

   part_begin     : array (1 .. NumThreads) of Integer;
   part_end       : array (1 .. NumThreads) of Integer;
begin
   create_array;
   sum_singlethread := part_sum (a'First, a'Last);

   Put_Line ("Single-thread sum: " & sum_singlethread'Img);

   for i in part_begin'Range loop
      part_begin (i) := a'First + (a'Last - a'First) * (i - 1) / NumThreads;
   end loop;

   for i in part_end'Range loop
      if i < part_end'Last then
         part_end (i) := part_begin (i + 1) - 1;
      else
         part_end (i) := a'Last;
      end if;
   end loop;

   for i in tasks'Range loop
      tasks (i).start (part_begin (i), part_end (i));
   end loop;

   sum_multithread := 0;
   task_manager.get_res (sum_multithread);

   Put_Line ("Multi-thread sum: " & sum_multithread'Img);

end main;
