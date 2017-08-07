// Função que fecha o pop-up ao clicar no botao fechar
function fechar(){
  document.getElementById('popup').style.display = 'none';
  document.getElementById('mask').style.display = 'none';
  setTimeout ("fechar()", 15000);
}
// Aqui definimos o tempo para fechar o pop-up automaticamente em milissengundos
function abrir(){
  document.getElementById('popup').style.display = 'block';
  setTimeout ("fechar()", 5000);
}
function trocaordem(){
  document.getElementById("popup").style.zIndex="1";
}
abrir();
