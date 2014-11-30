% Alexandre JADIN - Frederic KACZYNSKI
% -----------
% Version 2.0.0.0.1-prealpha-b10056 pa
     
local Mix Interprete Projet CWD ToNote ToDuree Bourdon Etirer Duree Transpose GetH ToVectorAudio EvaluateFunction ToFrequency Merge MergeX Intensity in
       % CWD contient le chemin complet vers le dossier contenant le fichier 'code.oz'
       % modifiez sa valeur pour correspondre à votre système.
   CWD = {Property.condGet 'testcwd' '/home/justice/Documents/Projet2014/'}
     
       % Si vous utilisez Mozart 1.4, remplacez la ligne précédente par celle-ci :
       % [Projet] = {Link ['Projet2014_mozart1.4.ozf']}
       %
       % Projet fournit quatre fonctions :
       % {Projet.run Interprete Mix Music 'out.wav'} = ok OR error(...)
       % {Projet.readFile FileName} = AudioVector OR error(...)
       % {Projet.writeFile FileName AudioVector} = ok OR error(...)
       % {Projet.load 'music_file.dj.oz'} = La valeur oz contenue dans le fichier chargé (normalement une <musique>).
       %
       % et une constante :
       % Projet.hz = 44100, la fréquence d'échantilonnage (nombre de données par seconde)
   [Projet] = {Link [CWD#'Projet2014_mozart2.ozf']}
     
   local
      Audio = {Projet.readFile CWD#'wave/animaux/cow.wav'}
   in
          % Mix prends une musique et doit retourner un vecteur audio.
      fun {Mix Interprete Music}
	 case Music
	 of nil then
	    nil
	 [] H|T then
	    {Append {Mix Interprete H} {Mix Interprete T}}
	 [] partition(1:Partition) then
	    % On transforme la partition en voix
	    {Mix Interprete voix({Interprete Partition})}
	 [] wave(1:NomFichier) then
	    Audio
	 [] voix(1:ListEchants) then
	    {ToVectorAudio ListEchants}
	 end
      end % fun
      
      fun{Merge Musics}
	 case Musics
	    of Float#Musique|T
	    then  {MergeX {Intensity Float Musique} {Merge T}}
	 [] nil then nil
	 []Float#Musique then {Intensity Float Musique}
	 end
      end

      fun{MergeX Music1 Music2}
	 case Music2 of H|T then 
	    case H of L1|L2 then % Music2 est une liste de musiques
	       {MergeX {MergeX Music1 H} T}
	    []nil then Music1
	    [] E then Music1.1+Music2.1|{MergeX Music1.2 Music2.2} %Music 2 est une liste de float
	    end
	 end
      end

      fun{Intensity Float Musique Acc} % peut être remplacé par  {List.map X fun {$ N} A*N end} Acc est un compteur pour {Fondu Open Close L1}
	 case Musique
	 of H|T then H*Float|{Intensity Float Musique}
	 [] nil then nil
	 end
      end

      fun{Fondu Open Close Music}
	 case Music of H|T then
	    case H of L.1 L.2 then {Append {Fondu Open Close L1} {Fondu Open Close L2}}
	    [] E then E %for 44100*open Intensity boucle?
	    end
	 end
      end  

      fun {EvaluateFunction Function Times}
	 local EvaluateFunctionAcc in
	    fun {EvaluateFunctionAcc Acc}
	       if Acc < Times then
		  R = {Function Acc}
	       in
		  R|{EvaluateFunctionAcc Acc+1.0}
	       else
		  {Browse finishVectorAudio}
		  nil
	       end
	    end
	    {EvaluateFunctionAcc 0.0}
	 end
      end

      fun {ToFrequency H}
	 {Number.pow 2.0 {Int.toFloat H}/12.0} * 440.0
      end
      
      fun {ToVectorAudio ListEchants}
	 case ListEchants
	 of nil then
	    nil
	 [] H|T then
	    case H
	    of echantillon(duree:Duree hauteur:Hauteur instrument:Instrument) then
	       Results = {EvaluateFunction fun {$ X} 0.5*{Float.sin (2.0*3.14159*{ToFrequency Hauteur}*X/44100.0)} end Duree*44100.0}
	    in
	       {Append Results {ToVectorAudio T}}
	    [] silence(duree:Duree) then
	       Results = {EvaluateFunction fun {$ X} 0.0 end Duree}
	    in
	       {Append Results {ToVectorAudio T}}
	    end
	 end
      end
     
      fun{GetH Note}
	 H in
	 case Note of note(nom:Nom octave:Octave alteration:none) then
	    case Nom
	    of a then H=0
	    [] b then H=2
	    [] c then H=~8
	    [] d then H=~6
	    [] e then H=~4
	    [] f then H=~3
	    [] g then H=~2
	    end
	    H+48-12*Octave
	 [] note(nom:Nom octave:Octave alteration:'# ') then
	    case Nom
	    of c then H=~7
	    [] d then H=~5
	    [] f then H=~3
	    [] g then H=~1
	    [] a then H=1
	    end
	    H+48-12*Octave
	 end %case
      end %fun
     
      fun {Bourdon ListEchants Note}
	 case ListEchants
	 of echantillon(hauteur:Hauteur duree:Duree instrument:Instrument)|T then
	    case Note
	    of silence then
	       silence(duree:Duree)|{Bourdon T Note}
	    else
	       echantillon(hauteur:Hauteur-2 duree:Duree instrument:Instrument)|{Bourdon T Note}
	    end
	 [] silence(duree:Duree)|T then
	    silence(duree:Duree)|{Bourdon T Note}
	 [] nil then
	    nil
	 end
      end
     
      fun {Etirer L Facteur}
	 case L
	 of echantillon(hauteur:Hauteur duree:Duree instrument:Instrument)|T then
	    echantillon(hauteur:Hauteur duree:(Duree*Facteur) instrument:Instrument)|{Etirer T Facteur}
	 [] silence(duree:Duree)|T then
	    silence(duree:(Duree*Facteur))|{Etirer T Facteur}
	 [] nil then
	    nil
	 end % case
      end % fun
     
      fun {Duree L Secondes DureeTotale}
	 case L of echantillon(hauteur:Hauteur duree:DureeEchant instrument:Instrument)|T then
	    echantillon(hauteur:Hauteur duree:(DureeEchant*Secondes/DureeTotale) instrument:Instrument)|{Duree T Secondes DureeTotale}
	 [] nil then
	    nil
	 [] silence(duree:DureeSilence)|T then
	    silence(duree:(DureeSilence*Secondes/DureeTotale))|{Duree T Secondes DureeTotale}
	 [] E then
	    {Duree [E] Secondes DureeTotale} % TODO
	 end
      end
     
      fun {ToNote Note}
	 case Note
	 of Nom#Octave then
	    note(nom:Nom octave:Octave alteration:'# ')
	 [] Atom then
	    case {AtomToString Atom}
	    of [ N ] then
	       note(nom:Atom octave:4 alteration:none)
	    [] [N O] then
	       note(nom:{StringToAtom [N]} octave:{StringToInt [O]} alteration:none)
	    end
	 end
      end
     
      fun{ToDuree EchList}
	 local ToDuree2 in
	    fun{ToDuree2 EchantList Acc}
	       case EchantList of H|T then
		  Acc=Acc+H.duree
		  {ToDuree T}
	       [] nil then
		  Acc
	       end %case
	    end %fun
	    {ToDuree2 EchList 0}
	 end %local
      end %fun
     
      fun{Transpose EchList DemiTons}
	 case EchList
	 of echantillon(hauteur:Hauteur duree:Duree instrument:Instrument)|T then
	    echantillon(hauteur:Hauteur+DemiTons duree:Duree instrument:Instrument)|{Transpose T DemiTons}
	 [] silence(duree:Duree)|T then
	    silence(duree:Duree)|{Transpose T DemiTons}
	 [] nil then
	    nil
	 end
      end
         
      % Interprete doit interpréter une partition
      fun {Interprete Partition}
	 case Partition
	 of H|T then
	    {Append {Interprete H} {Interprete T}}
	 [] etirer(1:PartitionIn facteur:Facteur) then
	    {Etirer {Interprete PartitionIn} Facteur}
	 [] muet(1:PartitionIn) then
	    {Bourdon {Interprete PartitionIn} silence}
         [] duree(1:PartitionIn secondes:Secondes) then
	    local
	       ListEchants = {Interprete PartitionIn}
	       DureeTotale = {ToDuree ListEchants}
	    in
	       {Duree ListEchants Secondes DureeTotale}
	    end
	 [] bourdon(1:PartitionIn note:Note) then
	    {Bourdon {Interprete PartitionIn} Note}
	 [] transpose(1:PartitionIn demitons:Demitons) then
	    {Transpose {Interprete PartitionIn} Demitons}
	 [] nil then
	    nil
	 [] E then
            % TODO Appliquer ToHauteur
	    local Note in
	       case E
	       of silence then
		  [silence(duree:1.0)]
	       else
		  Note = {ToNote E}
		  [echantillon(hauteur:{GetH Note} duree:1.0 instrument: none)]
	       end
	    end
	 end  % case
      end % fun
     
      local
	 Music = {Projet.load CWD#'joie.dj.oz'}
      in
          % Votre code DOIT appeler Projet.run UNE SEULE fois.  Lors de cet appel,
          % vous devez mixer une musique qui démontre les fonctionalités de votre
          % programme.
          %
          % Si votre code devait ne pas passer nos tests, cet exemple serait le
          % seul qui ateste de la validité de votre implémentation.
	 {Browse {Projet.run Mix Interprete Music CWD#'out.wav'}}
      end
   end
end

