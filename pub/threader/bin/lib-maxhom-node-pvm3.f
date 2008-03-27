C============================================  PVM3
C maxhom node interface for PVM3
	subroutine node_interface(lh1,lh2)
 
	implicit none
	include 'maxhom.param'
	include 'maxhom.common'
c import
	real      lh1(0:maxmat)
	integer*2 lh2(0:maxtrace)
 
c internal
C on a mixed architecture network the node is reading the alignment
C data on request and sends them to the host
C local for each node
	real      value,sim,hom,rms,distance,checkval,sdev
	integer ifir,jfir,jlas,idel,ndel,len1,lenocc
	integer irecord,nrecord,ialign,ifile,imsgtag
	integer i,j,k,ipoint,iend
	integer ilen_name,ilen_compnd,ilen_ACCESSION,ilen_pdbref,ilen_al
	integer ilen_insseq
	integer ilconsider,ildssp_2
	character*100 coretemp
	character csymbol,ctemp
	logical lerror
c       logical lendbase
 
        integer file_buffer(maxqueue),nfile_queue
	character*80 filename_buffer(maxqueue_list)
	character*80 filename,tempname
        character pdbrefline*3000
	character*80 chainremark,profilemetric
   	character line*100
 
 
	integer iseq,ibuf_poi
 
c checkformat
	character*20 seqformat
	integer ifirst_round,iflag
	integer ipos,nchain,kselect
c	integer kchain
	real xmaplow,xmaphigh,xsmin,xsmax
        logical ltruncated
c        logical ldb_read_one
 
C init
C timing
        total_time=0.0
	current_dir=' ' 
         architecture=' '
	lfirst_scan=.true.
 
c        ldb_read_one=.false.
 
	nbuffer_len = 6 + 12 + len(compnd_2) +
     +   len(ACCESSION_2) + len(pdbref_2)
c	nbuffer_len = 6 + len(name_2) + len(compnd_2) +
c     +   len(ACCESSION_2) + len(pdbref_2)
 
	call get_machine_name(machine_name)
	tempname='ARCH'
	call get_enviroment_variable(tempname,architecture)
	tempname='MAXHOM_DEFAULT'
	call get_enviroment_variable(tempname,maxhom_default)
	if(maxhom_default .eq. ' ')then
	   write(*,*)'WARN: env.var. MAXHOM_DEFAULT not set; '//
     +               'now: ./maxhom.default'
	   maxhom_default(1:)='maxhom.default'
	   call flush_unit(6)
	endif
c	write(*,'(a,a,a,a,i5)')' maxhom_node : ',
c     +        machine_name(1:15),' ',architecture(1:6),idproc
c	call flush_unit(6)
 
C receive all the necessary data from host
C loop entry for list processing
 10	call receive_data_from_host(id_host) 
         call flush_unit(6)
c open log file for parameter,warnings, error.....
	if(lfirst_scan .eqv. .true.)then
	   call concat_string_int('MAXHOM.LOG_',idproc,logfile)
           tempname=logfile
	   if(corepath .ne. ' ')then
	     call concat_strings(corepath,tempname,logfile)
           endif
c          tempname= 'NEW,RECL=200'
c	   call open_file(klog,logfile,tempname,lerror)
c	   call log_file(klog,'**************************** MAXHOM-'//
c     +         'LOGFILE ***************************',1)
	endif
C end signal if we had a list of sequences
	if(n1 .eq. -999) goto 900
 
 	do i=1,maxqueue
	   file_buffer(i) = 0
	enddo
 	do i=1,maxqueue_list
	   filename_buffer(i)=' '
	enddo
	ipoint=1
	ialign=0 
         nrecord=0 
         irecord=0 
         ifile=0 
         ialign_good=0
	insseq=' ' 
         sdev=0.0
 
C overwrite default stuff in case the actual machine is on a different
C file system (connected via Ethernet, Internet..)
C Caution: maxhom.default has to be on the right place
c	call get_default()
 
   	ldssp_2=.false. 
         n2in=0 
         csymbol=' ' 
         csq_2=' '
	header_2=' ' 
         compnd_2=' ' 
         author_2=' ' 
         source_2=' '
	do i=1,maxsq
	   cresid(i)=' ' 
         pdbno_2(i)=0 
         bp1_2(i)=0 
         bp2_2(i)=0
	   lacc_2(i)=0 
         lstruc_2(i)=0 
         consweight_2(i)=1.0
	enddo
	call init_char_array(1,maxsq,cols_2,csymbol)
	call init_char_array(1,maxsq,chainid_2,csymbol)
	call init_char_array(1,maxsq,sheetlabel_2,csymbol)
	call init_char_array(1,maxsq,struc_2,csymbol)
 
	call concat_string_int(corefile,link(idproc),tempname)
	coretemp= tempname
	if(corepath .ne. ' ')then
	  call concat_strings(corepath,tempname,coretemp)
        endif
	call concat_string_int('UNFORMATTED,DIRECT,NEW,RECL=',
     +                          maxrecordlen,tempname)
c	write(*,*)idproc,' : ',coretemp(1:60)
c	call flush_unit(6)
	call open_file(kcore,coretemp,tempname,lerror)
 
 
c$$$    if (ldb_read_one .eqv. .true.)then
c$$$           lfirst_scan=.false.
c$$$           msgtype=8000
c$$$	   call mp_receive_data(msgtype,link(id_host))
c$$$	   call mp_get_int4(msgtype,id_host,ipoint,N_one)
c$$$	   call mp_get_int4(msgtype,id_host,nseq_warm_start,N_one)
c$$$           msgtype=9000
c$$$	   call mp_receive_data(msgtype,link(id_host))
c$$$	   call mp_get_string_array(msgtype,id_host,cdatabase_buffer,
c$$$     +                              ipoint)
c$$$           msgtype=10000
c$$$	   call mp_receive_data(msgtype,link(id_host))
c$$$	   call mp_get_int4(msgtype,id_host,i,N_one)
c$$$	   write (*,*)' got buffer and start signal: ',idproc,ipoint,
c$$$     +                nseq_warm_start
c$$$           call flush_unit(6)
c$$$	   ipoint=1
c$$$	endif
 
        call get_cpu_time('time init:',idproc,
     +                        itime_old,itime_new,total_time,logstring)
	call log_file(klog,logstring,1)
 
C======================================================================
C NO warm-start
C======================================================================
	if(lfirst_scan .eqv. .true.)then
	  lfirst_scan=.false.
	  nfile_queue=0
	  ifirst_round=0
 
 
 
c fill queue when first communication
	     if( listofseq_2 .eqv. .true.)then
		msgtype=9000
		do i=1,maxqueue_list
		   call mp_receive_data(msgtype,link(id_host))
		   call mp_get_string(msgtype,id_host,
     +                 filename_buffer(i),len(filename_buffer(i)))
		   write(*,'(a,a,i6)')'1. got: ',
     +                   filename_buffer(i)(1:30),idproc
		   call flush_unit(6)
	           if (filename_buffer(i) .eq. 'STOP')then
		      nfile_queue=i
		      goto 180
		   endif
		enddo
		ifirst_round=1
		nfile_queue=maxqueue_list
		goto 180
	     endif
 
 
 
 
 
 
c check if there is a (are) message(s) from the host to
C  fill our work-queue
C if not, work on the next file on the stack
 
100	  msgtype=3000
	  call mp_probe(msgtype,iflag)
	  if ( iflag .gt. 0)then
	    nfile_queue=nfile_queue+1
	    call mp_receive_data(msgtype,link(id_host))
 
	    if( listofseq_2 .eqv. .false.)then
	       call mp_get_int4(msgtype,id_host,
     +                          file_buffer(nfile_queue),N_one)
c	    write(logstring,*)'fill file stack: ',idproc,nfile_queue,
c     +                 file_buffer(nfile_queue)
c	    call log_file(klog,logstring,1)
	       if (file_buffer(nfile_queue) .lt. 0)goto 180
	       goto 100
	    else
	       call mp_get_string(msgtype,id_host,
     +                           filename_buffer(nfile_queue),
     +	                         len(filename_buffer(1)) )
	       if (filename_buffer(nfile_queue) .eq. 'STOP')goto 180
	       goto 100
	    endif
	  endif
C send work-request to host
	  msgtype=2000
	  call mp_init_send()
	  call mp_put_int4(msgtype,id_host,idproc,N_one)
	  call mp_send_data(msgtype,link(id_host))
c	  write(logstring,'(a,i4,i4)')'send work_message:',idproc,
c     +                                link(id_host)
c	  call log_file(klog,logstring,1)
	  msgtype=3000
c fill queue when first communication
	  if (ifirst_round .eq. 0) then
	     if( listofseq_2 .eqv. .false.)then
		call mp_receive_data(msgtype,link(id_host))
		do i=1,maxqueue
		   call mp_get_int4(msgtype,id_host,file_buffer(i),
     +                              N_one)
		enddo
		ifirst_round=1
		nfile_queue=maxqueue
c	     else
c		do i=1,maxqueue_list
c		   call mp_receive_data(msgtype,link(id_host))
c		   call mp_get_string(msgtype,id_host,
c     +                 filename_buffer(i),len(filename_buffer(i)))
c		   write(*,'(a,a,i6)')'1. got: ',
c     +                   filename_buffer(i)(1:30),idproc
c		   call flush_unit(6)
c	           if (filename_buffer(i) .eq. 'STOP')then
c		      nfile_queue=i
c		      goto 180
c		   endif
c		enddo
c		ifirst_round=1
c		nfile_queue=maxqueue_list
	     endif
c either the master is too slow, so we have to wait :-(
c or we have finished the work and are waiting for 
C the "finish-signal" :-)
	  else if (nfile_queue .le. 0)then
	     write(logstring,'(a,i8,2x,i6)')'WARNING stack empty: ',
     +                         idproc,file_buffer(1)
	     call log_file(klog,logstring,1)
             call flush_unit(6)
	     call mp_receive_data(msgtype,link(id_host))
	     if( listofseq_2 .eqv. .false.)then
		call mp_get_int4(msgtype,id_host,file_buffer(1),N_one)
	     else
		call mp_get_string(msgtype,id_host,
     +                             filename_buffer(1),
     +                             len(filename_buffer(1)))
	     endif
	     nfile_queue=1
	  endif
C ======================================================================
C database
C ======================================================================
 180	  if(listofseq_2 .eqv. .false.)then
C next file is always the first on the stack
 	     ifile=file_buffer(1)
C now the real work starts
	     if(ifile .gt. 0)then
c            write(logstring,'(a,i8,i4)')'work on file:',idproc,
c     +                       file_buffer(1)
c	        call log_file(klog,logstring,1)
 
		call open_sw_data_file(kbase,lbinary,ifile,
     +                             split_db_data,split_db_path,hostname)
		if(lwarm_start .eqv. .false.)ipoint=1
 
		if(lbinary .eqv. .true.)then
		   read(kbase)ibuf_poi,iseq
		else
		   read(kbase,'(i10,i10)')ibuf_poi,iseq
		endif
		if(ipoint + ibuf_poi .lt. maxdatabase_buffer)then
		   if(lbinary .eqv. .true.)then
		     read(kbase)
     +             (cdatabase_buffer(i),i=ipoint,ipoint+ibuf_poi-1)
		   else
		     read(kbase,'(a)')
     +              (cdatabase_buffer(i),i=ipoint,ipoint+ibuf_poi-1)
		   endif
		   close(kbase)
 
 
		   do k=1,iseq
		      do ipos=1,nbuffer_len
			 cbuffer_line(ipos:ipos)=
     +                  cdatabase_buffer(ipoint)
			 ipoint=ipoint+1
		      enddo
		      read(cbuffer_line(1:),111)n2in,name_2,
     +                    ACCESSION_2,pdbref_2,compnd_2
c		      read(cbuffer_line(1:),111)n2in,name_2,
c     +		   compnd_2,ACCESSION_2,pdbref_2
111		      format(i6,a12,a,a,a)
		      iend=n2in
		      if(n2in .gt. maxsq)iend=maxsq
		
		      do ipos=1,iend
			 csq_2(ipos:ipos)=cdatabase_buffer(ipoint)
			 ipoint=ipoint+1
		      enddo
		      if(n2in .gt. maxsq)then
			 ipoint=ipoint + (n2in-iend)
			 n2in=maxsq
		      endif
 
		      call do_align(lh1,lh2,idproc,ialign,nrecord,sdev)
c		      ialign_processed=ialign_processed+1		
		   enddo
		else
		   write(logstring,*)' ** FATAL ERROR **/n'//
     +		' database_buffer overflow increase/n'//
     +		' dimension of MAXDATABASE_BUFFER'
		   call log_file(klog,logstring,1)
		   STOP
		endif
 
		nseq_warm_start=ialign
c refresh the content of the work-queue
		nfile_queue=nfile_queue-1
		do i=1,nfile_queue
		   file_buffer(i) = file_buffer(i+1)
		enddo
c	    write(logstring,'(a,i4,i4)')'on stack:',idproc,nfile_queue
c	        call log_file(klog,logstring,1)
		if ( nfile_queue .gt. 0)then
		   if (file_buffer(nfile_queue) .lt. 0)then
		      goto 180
		   endif
		endif
		goto 100
	     endif
C=======================================================================
C list of filenames
C=======================================================================
	  else
C next file is always the first on the stack
	     filename=filename_buffer(1)
C now the real work starts
	     if(filename .ne. 'STOP')then
		name_2=filename
		call checkformat(kbase,name_2,seqformat,lerror)
		if(index(seqformat,'PROFILE') .ne. 0)lprofile_2=.true.
		if(index(seqformat,'DSSP'   ) .ne. 0)ldssp_2=.true.
		if(lprofile_2)then
c		   write(logstring,'(a,a)')'read PROFILE 2: ',name_2
c		   call log_file(klog,logstring,1)
		   call readprofile(kprof,name_2,maxsq,ntrans,trans,
     +                   ldssp_2,n2in,nchain,hsspid_2,header_2,compnd_2,
     +                   source_2,author_2,xsmin,xsmax,xmaplow,xmaphigh,
     +                   profilemetric,pdbno_2,chainid_2,csq_2_array,
     +	                 struc_2,nsurf_2,cols_2,sheetlabel_2,bp1_2,
     +	                 bp2_2,nocc_2,gapopen_2,gapelong_2,consweight_2,
     +                   simmetric_2,maxbox,nbox_2,profilebox_2)
		   do i=1,n2in
                      csq_2(i:i)=csq_2_array(i)
		   enddo
caution
C cstrstates,simorg and lsq_2 not known here
C pass simorg and set lsq_2
		   if(metricfile .ne. 'PROFILE')then
		       write(*,*)' option not possible, ask reinhard'
		       stop
		   endif
		   if(smin_answer .eq. 'PROFILE')then
                      smin=xsmin 
         smax=xsmax 
         maplow=xmaplow
	              maphigh=xmaphigh
		   else if(lprofile_2 .and. smin_answer .ne.
     +                      'PROFILE')then
	              maplow=xmaplow 
         maphigh=xmaphigh
		   endif
		   if(openweight_answer .ne. 'PROFILE')then
	              do i=1,maxsq 
         gapopen_2(i)=open_1 
         enddo
		   endif
	           if(elongweight_answer .ne. 'PROFILE')then
	              do i=1,maxsq 
         gapelong_2(i)=elong_1 
         enddo
	           endif
C reset conservation weights for sequence 2 if not wanted
	           if(.not. lconserv_2 )then
                      do i=1,maxsq 
         consweight_2(i)=1.0 
         enddo
	           endif
		   lnorm_profile=.false.
 
c	            if(lnorm_profile)then
c	              write(*,*)'CALL NORM_PROFILE '
c                      smin=0.0   ; smax=0.0
c	              maplow=0.0 ; maphigh=0.0
c	              call norm_profile(maxsq,ntrans,trans,n2in,n1,
c     +                             lsq_1,simmetric_2,profile_epsilon,
c     +                             profile_gamma,smin,smax,maplow,
c     +                             maphigh,gapopen_2,gapelong_2,sdev)
c	            else
c		   write(*,*)' call scale_profile disabled'
 
c	              write(*,'(a,4(2x,f5.2)))')'CALL SCALE_PROFILE 2',
c     +                          smin,smax,maplow,maphigh
c	              call scale_profile_metric(maxsq,ntrans,trans,
c     +                            simmetric_2,smin,smax,maplow,maphigh)
c	            endif
C not profile
		else
C all chains wanted from dssp data set
		   call checkformat(kbase,name_2,seqformat,lerror)
		   if(index(seqformat,'DSSP') .ne. 0 .or.
     +	              index(seqformat,'PROFILE-DSSP') .ne.0)then
                      ldssp_2=.true.
		   endif
 
c		   kchain=0
		   tempname=' '
		   i=index(name_2,'_!_')
		   if(i.ne.0)then
	              tempname(1:)=name_2(1:i-1)
                      ctemp(1:)=name_2(i+3:)
		   else
	              tempname(1:)=name_2(1:)
                      ctemp=' '
		   endif
		   pdbrefline=' '
		   if(ldssp_2 .eqv. .false.)then
                       call get_seq(kbase,tempname,trans,ctemp,
     +                   compnd_2,ACCESSION_2,pdbrefline,pdbno_2,n2in,
     +                   csq_2,struc_2_string,nsurf_2,ltruncated,
     +                   lerror)
C convert cresid to pdb-number and chain identifier, used in 3d
C superposition cresid from getseq is :
C "1234AB" (number, alternate residue, chain identifier)
C here skip alternate residue and append chain_id
                       do i=1,n2in 
         csq_2_array(i)=csq_2(i:i)
                          struc_2(i)=struc_2_string(i:i)
                          read(cresid(i),'(i4,1x,a)')
     +                         pdbno_2(i),chainid_2(i)
                       enddo
		   else
C all chains wanted from DSSP data set
		      k=0 
         chainremark=' '
		      i=index(tempname,'!')-1
		      if(i .gt. 0)then
			 kselect=1 
         iend=len(tempname)
			 do j=iend,i+1,-1
			    if(tempname(j:j) .eq. ',')kselect=kselect+1
			 enddo
			 write(*,*)' use ',kselect,' chain(s) ',
     +                               tempname(i:)
                           chainremark(1:)=tempname
                      else
			 call select_unique_chain(kgetseq,
     +		                       tempname,line)
			 chainremark= line(1:80)
		      endif
		      j=1
		      call getdsspforhssp(kgetseq,tempname,
     +                        maxsq,chainremark,
     +		              brkid_2,header_2,compnd_2,source_2,
     +	                      author_2,n2in,i,j,k,pdbno_2,
     +                        chainid_2,csq_2_array,struc_2,cols_2,
     +	                      bp1_2,bp2_2,sheetlabel_2,nsurf_2)
		      do i=1,n2in
			 csq_2(i:i)=csq_2_array(i)
		      enddo
		   endif
		   call select_pdb_pointer(kref,dssp_path,pdbrefline,
     +                                pdbref_2)
		endif
		call do_align(lh1,lh2,idproc,ialign,nrecord,sdev)
c refresh the content of the work-queue
		nfile_queue=nfile_queue-1
		do i=1,nfile_queue
		   filename_buffer(i) = filename_buffer(i+1)
		enddo
	
		if ( nfile_queue .gt. 0)then
		   if (filename_buffer(nfile_queue) .eq. 'STOP')then
		      goto 180
		   endif
		endif
		goto 100
	     endif
C=====================================================================
C list of filename
C=====================================================================
	  endif
	  call get_cpu_time('database scan: ',idproc,
     +                        itime_old,itime_new,total_time,logstring)
	  call log_file(klog,logstring,1)
	  write(logstring,'(a,i6,i8,i10)')'internal buffer: ',idproc,
     +                                nseq_warm_start,ipoint
	  call log_file(klog,logstring,1)
	  if(listofseq_2 .eqv. .true.)lfirst_scan=.true.
 
C=======================================================================
C warm start
C=======================================================================
	else
	  do i=1,nseq_warm_start
             do ipos=1,nbuffer_len
                cbuffer_line(ipos:ipos)=cdatabase_buffer(ipoint)
                ipoint=ipoint+1
             enddo
             read(cbuffer_line(1:),111)n2in,name_2,
     +             compnd_2,ACCESSION_2,pdbref_2
	     iend=n2in
	     if(n2in .gt. maxsq)iend=maxsq
	
	     do ipos=1,iend
		csq_2(ipos:ipos)=cdatabase_buffer(ipoint)
		ipoint=ipoint+1
	     enddo
	     if(n2in .gt. maxsq)then
		ipoint=ipoint + (n2in-iend)
		n2in=maxsq
	     endif
	     call do_align(lh1,lh2,idproc,ialign,nrecord,sdev)
	  enddo
c	  ialign_processed=nseq_warm_start
	  call get_cpu_time('database scan warm start: ',idproc,
     +                        itime_old,itime_new,total_time,logstring)
	  call log_file(klog,logstring,1)
C=====================================================================
C end warm-start
C=======================================================================
	endif
C=====================================================================
C send results to host
c	write (logstring,'(a,i4)')'got end signal: ',idproc
c	call log_file(klog,logstring,1)
 
	msgtype=4000
	call mp_init_send()
	call mp_put_int4(msgtype,id_host,ialign,N_one)
	call mp_put_int4(msgtype,id_host,ialign_good,N_one)
	call mp_send_data(msgtype,link(id_host))
   	if(ialign .gt. 0)then
	   msgtype=5000
	   call mp_init_send()
	   call mp_put_real4_array(msgtype,id_host,alisortkey,ialign)
	   call mp_put_int4_array(msgtype,id_host,irecpoi,ialign)
	   call mp_put_int4_array(msgtype,id_host,ifilepoi,ialign)
	   call mp_send_data(msgtype,link(id_host))
 
	   write (logstring,'(a,i6,2x,i6)')
     +	   'send result OK: ',idproc,ialign
	   call log_file(klog,logstring,1)
	else
	   write (logstring,'(a,i6)')'nothing found: ',idproc
	   call log_file(klog,logstring,1)
	endif
C on a mixed architecture cluster wait for request from host for
C the alignment data and send them
c	if(lmixed_arch )then
	  ilen_name=len(name_2)    
         ilen_compnd=len(compnd_2)
	  ilen_ACCESSION=len(ACCESSION_2) 
         ilen_pdbref=len(pdbref_2)
	  ilen_al=len(al_2) 
         ilen_insseq=len(insseq)
 
200	  msgtype=6000
 
	  call mp_receive_data(msgtype,link(id_host))
	  call mp_get_int4(msgtype,id_host,irecord,N_one)
	  call mp_get_int4(msgtype,id_host,imsgtag,N_one)
	  call mp_get_real4(msgtype,id_host,checkval,N_one)
c	  write (*,*)' request: ',idproc,irecord ; call flush_unit(6)
	  if(irecord .le. 0)goto 300
	  call getalign(kcore,irecord,ifir,len1,lenocc,jfir,jlas,
     +                  idel,ndel,value,rms,hom,
     +                  sim,sdev,distance,checkval)
 
 
	  ilconsider=0 
         ildssp_2=0
          if( lconsider )ilconsider=1 
         if( ldssp_2 )ildssp_2=1
 
	  msgtype=imsgtag
	  call mp_init_send()
	  call mp_put_int4(msgtype,id_host,ilconsider,N_one)
	  call mp_put_int4(msgtype,id_host,ildssp_2,N_one)
	  call mp_put_string(msgtype,id_host,name_2,ilen_name)
	  call mp_put_string(msgtype,id_host,compnd_2,ilen_compnd)
	  call mp_put_string(msgtype,id_host,ACCESSION_2,ilen_ACCESSION)
	  call mp_put_string(msgtype,id_host,pdbref_2,ilen_pdbref)
	  call mp_put_real4(msgtype,id_host,value,N_one)
	  call mp_put_int4(msgtype,id_host,ifir,N_one)
	  call mp_put_int4(msgtype,id_host,len1,N_one)
	  call mp_put_int4(msgtype,id_host,lenocc,N_one)
	  call mp_put_int4(msgtype,id_host,jfir,N_one)
	  call mp_put_int4(msgtype,id_host,jlas,N_one)
	  call mp_put_int4(msgtype,id_host,n2in,N_one)
	  call mp_put_int4(msgtype,id_host,idel,N_one)
	  call mp_put_int4(msgtype,id_host,ndel,N_one)
	  call mp_put_int4(msgtype,id_host,nshifted,N_one)
	  call mp_put_real4(msgtype,id_host,rms,N_one)
	  call mp_put_real4(msgtype,id_host,hom,N_one)
	  call mp_put_real4(msgtype,id_host,sim,N_one)
	  call mp_put_real4(msgtype,id_host,sdev,N_one)
	  call mp_put_real4(msgtype,id_host,distance,N_one)
c	  call mp_put_string(msgtype,id_host,al_1,ilen_al)
	  call mp_put_string(msgtype,id_host,al_2,ilen_al)
	  call mp_put_string(msgtype,id_host,sal_2,ilen_al)
	  call mp_put_int4(msgtype,id_host,iins,N_one)
	  if(iins .gt. 0)then
	    call mp_put_int4_array(msgtype,id_host,inslen_local,iins)
	    call mp_put_int4_array(msgtype,id_host,insbeg_1_local,iins)
	    call mp_put_int4_array(msgtype,id_host,insbeg_2_local,iins)
	    call mp_put_string(msgtype,id_host,insseq,ilen_insseq)
	  endif
	  call mp_send_data(msgtype,link(id_host))
c	  write (*,*)' request send: ',idproc ; call flush_unit(6)
 
	  goto 200
c	endif
300	close(kcore)
c	if(lmixed_arch )then
	call del_oldfile(kcore,coretemp)
c	endif
 
	if ( (l3way .eqv. .true. ) .and.
     +       (l3waydone .eqv. .false.) )then
	   l3waydone=.true.
	   write(*,*)' second scan; go back to start:', idproc
	   goto 10
	endif
 
	if(lwarm_start)then
	   write(*,*)' warm-start; go back to start:', idproc
	   goto 10
	endif
900	call get_cpu_time('time finish: ',idproc,
     +                        itime_old,itime_new,total_time,logstring)
	call log_file(klog,logstring,1)
	return
	end
C END NODE_INTERFACE....................................................
 
C SUBROUTINE REPORT_TIME...............................................
c	subroutine report_time(klog,maxstep,text,idproc,itime,istep,
c     +                         total_time)
C import
c	integer klog,maxstep,idproc,itime(0:maxstep,*),istep
c	real total_time
c	character*(*) text(*)
C internal
c	character*200 logstring
c	integer i
c	real xtime1,xtime2,xtime3
c	real one_sec
c	parameter (one_sec=1000000.0)
c	write(logstring,*)' timing: '
c	call log_file(klog,logstring,2)
c	do i=1,istep
c	  xtime1= float(itime(i,1)) / one_sec
c	  xtime2= float(itime(i,2)) / one_sec
c	  xtime3= float(itime(i,3)) / one_sec
c
c	  write(logstring,'(a,i6,3(f10.2))')text(i),idproc,
c     +                    xtime1,xtime2,xtime3
c	  call log_file(klog,logstring,2)
c	enddo
c	write(logstring,*)' total: ',total_time
c	call log_file(klog,logstring,2)
c	return
c	end
C END REPORT_TIME.......................................................
 
C============================================
C maxhom host working interface for PVM3
	subroutine host_interface(lh1,lh2,ifile,filename,ialign,
     +                            nrecord,ipoint)
 
	implicit none
	include 'maxhom.param'
	include 'maxhom.common'
c import
	character*(*) filename
	real      lh1(0:maxmat)
	integer*2 lh2(0:maxtrace)
 
c	real lh(0:maxmat*2)
	integer ipoint
c internal
C local for each node
	real    sdev
	integer nrecord,ialign,ifile,iseq,k
c	logical lendbase
	integer ipos,i,ibuf_poi,iend
C init
	nbuffer_len = 6 + 12 + len(compnd_2) +
     +                len(ACCESSION_2) + len(pdbref_2)
 
c	nbuffer_len = 6 + len(name_2) + len(compnd_2) +
c     +                len(ACCESSION_2) + len(pdbref_2)
	sdev=0.0
 
 111	format(i6,a12,a,a,a)
	if(lfirst_scan .eqv. .true.)then
	   call open_sw_data_file(kbase,lbinary,ifile,split_db_data,
     +                            split_db_path,hostname)
 
	   if(lwarm_start .eqv. .false.)ipoint=1
	   if(lbinary .eqv. .true.)then
	      read(kbase)ibuf_poi,iseq
	   else
	      read(kbase,'(i10,i10)')ibuf_poi,iseq
	   endif
	   if(ipoint + ibuf_poi .lt. maxdatabase_buffer)then
	      if(lbinary .eqv. .true.)then
		 read(kbase)
     +           (cdatabase_buffer(i),i=ipoint,ipoint+ibuf_poi-1)
	      else
		 read(kbase,'(a)')
     +         (cdatabase_buffer(i),i=ipoint,ipoint+ibuf_poi-1)
	      endif
	      close(kbase)
	      do k=1,iseq
		 do ipos=1,nbuffer_len
		    cbuffer_line(ipos:ipos)=cdatabase_buffer(ipoint)
		    ipoint=ipoint+1
		 enddo
		 read(cbuffer_line(1:),111)n2in,name_2,
     +	      ACCESSION_2,pdbref_2,compnd_2
c		 read(cbuffer_line(1:),111)n2in,name_2,
c     +	      compnd_2,ACCESSION_2,pdbref_2
 
		 iend=n2in
		 if(n2in .gt. maxsq)iend=maxsq
 
		 do ipos=1,iend
		    csq_2(ipos:ipos)=cdatabase_buffer(ipoint)
		    ipoint=ipoint+1
		 enddo
		 if(n2in .gt. maxsq)then
		    ipoint=ipoint + (n2in-iend)
		    n2in=maxsq
		 endif
		 call do_align(lh1,lh2,idproc,ialign,nrecord,sdev)
		 nseq_warm_start=nseq_warm_start+1
	      enddo
	   else
	      write(logstring,*)' ** FATAL ERROR **/n'//
     +	   ' database_buffer overflow increase/n'//
     +	   ' dimension of MAXDATABASE_BUFFER'
	      call log_file(klog,logstring,1)
	      STOP
	   endif
 
c	   lendbase=.false.
c	   do while(.not. lendbase)
c	     call get_swiss_entry(maxsq,kbase,lbinary,n2in,name_2,
c     +	              compnd_2,ACCESSION_2,pdbref_2,csq_2,lendbase)
c	     if(.not. lendbase)then
c               if (lwarm_start) then
c                  if( (ipoint + nbuffer_len + n2in) .gt.
c     +                 maxdatabase_buffer)then
c                    write(*,*)' **** FATAL ERROR ****'
c                    write(*,*)' database_buffer overflow increase'
c                    write(*,*)' dimension of MAXDATABASE_BUFFER'
c                    STOP
c                  endif
c                  write(cbuffer_line(1:),'(i6,a,a,a,a)')n2in,name_2,
c     +                  compnd_2,ACCESSION_2,pdbref_2
c                  do ipos=1,nbuffer_len
c                     cdatabase_buffer(ipoint)=cbuffer_line(ipos:ipos)
c                     ipoint=ipoint+1
c                  enddo
c                  do ipos=1,n2in
c                     cdatabase_buffer(ipoint)=csq_2(ipos:ipos)
c                     ipoint=ipoint+1
c		  enddo
c               endif
c	       call do_align(lh1,lh2,idproc,ialign,nrecord,sdev)
c	       nseq_warm_start=nseq_warm_start+1
c	     endif
c	  enddo
c	  close(kbase)
	else
	   write(*,*)' host warm-start: ',nseq_warm_start
	  do i=1,nseq_warm_start
             do ipos=1,nbuffer_len
                cbuffer_line(ipos:ipos)=cdatabase_buffer(ipoint)
                ipoint=ipoint+1
             enddo
c	     write(*,*)cbuffer_line,ipoint
             read(cbuffer_line(1:),111)n2in,name_2,
     +             compnd_2,ACCESSION_2,pdbref_2
 
	     iend=n2in
	     if(n2in .gt. maxsq)iend=maxsq
	
	     do ipos=1,iend
		csq_2(ipos:ipos)=cdatabase_buffer(ipoint)
		ipoint=ipoint+1
	     enddo
	     if(n2in .gt. maxsq)then
		ipoint=ipoint + (n2in-iend)
		n2in=maxsq
	     endif
	     call do_align(lh1,lh2,idproc,ialign,nrecord,sdev)
	  enddo
	endif
 
	return
	end
C END HOST_INTERFACE....................................................
