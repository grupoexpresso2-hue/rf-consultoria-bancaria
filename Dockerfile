FROM nginx:alpine

# Remove a configuração padrão e aplica a customizada
RUN rm -f /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copia o site
COPY index.html /usr/share/nginx/html/index.html
COPY robots.txt sitemap.xml /usr/share/nginx/html/
COPY img/ /usr/share/nginx/html/img/

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1/healthz || exit 1

CMD ["nginx", "-g", "daemon off;"]
