for i in `ls *.pl` 
do 
   echo $i; 
   perl -c $i;
done
 